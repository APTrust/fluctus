require 'spec_helper'

describe Auditable do

  class ObjectWithAuditEvents < ActiveFedora::Base
    include Auditable

    def uri
      'hello from uri method'
    end
  end

  subject { ObjectWithAuditEvents.new }

  before do
    @inst_id = '456'
    inst = double('institution', id: @inst_id)
    subject.stub(:institution).and_return(inst)
  end

  let(:field_name_base) { subject.class.to_s.underscore }

  describe 'solr fields that describe the parent object of an event' do

    it 'has a base name for solr fields that describe the parent' do
      subject.namespaced_solr_field_base.should == field_name_base
    end
  end


  it 'has a premisEvents datastream' do
    subject.premisEvents.should be_kind_of PremisEventsMetadata
  end

  describe 'adding a new event' do
    let(:attrs) { FactoryGirl.attributes_for(:premis_event_ingest) }

    it 'returns the event' do
      subject.add_event(attrs).class.should == Event
    end

    it 'saves the new event to the premisEvents datastream' do
      subject.add_event(attrs)
      subject.save!

      reload = ActiveFedora::Base.find(subject.id)
      reload.premisEvents.events.length.should == 1
      event = reload.premisEvents.events.first
      event.outcome.should == ['success']
      event.type.should == ['ingest']
      event.detail.first.should =~ /copy to s3/i
    end

    it 'doesnt delete any previously exising events' do
      subject.premisEvents.events_attributes = [FactoryGirl.attributes_for(:premis_event_fixity_generation)]
      subject.save!
      subject.premisEvents.events.length.should == 1
      subject.add_event(attrs)
      subject.save!

      reload = ActiveFedora::Base.find(subject.id)
      reload.premisEvents.events.length.should == 2
      event = reload.premisEvents.events.last
      event.outcome.should == ['success']
      event.type.should == ['ingest']
      event.detail.first.should =~ /copy to s3/i
    end

    it 'writes a solr doc for the new event that includes the id of the parent object and the institution id' do
      subject.save!

      event_id = '123'
      params = attrs.merge(identifier: event_id)
      subject.add_event(params)

      subject.premisEvents.events.count.should == 1
      event = subject.premisEvents.events.first

      solr_result = ActiveFedora::SolrService.query("id:#{event_id}").first
      solr_result['institution_id_ssim'].should == [@inst_id]
      solr_result["#{field_name_base}_id_ssim"].should == [subject.id]
      solr_result["#{field_name_base}_uri_ssim"].should == [subject.uri]
    end

    it 'it indexes the intellectual_object_id' do
      subject.save!
      id = '111'
      subject.stub(:intellectual_object_id).and_return(id)
      subject.add_event(attrs)

      subject.premisEvents.events.count.should == 1
      event = subject.premisEvents.events.first
      solr_result = ActiveFedora::SolrService.query("id:#{event.identifier.first}").first
      solr_result["intellectual_object_id_ssim"].should == [id]
    end

  end

end
