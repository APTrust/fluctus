require 'spec_helper'

describe Auditable do

  class ObjectWithAuditEvents < ActiveFedora::Base
    include Auditable
  end

  subject { ObjectWithAuditEvents.new }

  let(:parent_object_key) { "#{subject.class.to_s.underscore}_id" }

  it 'has a name for the id of the parent object of an event' do
    # Example:  A GenericFile that has a premisEvent.
    # When the event gets written to solr, it will have a
    # field called generic_file_id_* to identify which
    # GenericFile the premisEvent belongs to.
    subject.parent_key_for_events.should == parent_object_key
  end

  it 'has a premisEvents datastream' do
    subject.premisEvents.should be_kind_of PremisEventsMetadata
  end

  describe 'adding a new event' do
    let(:attrs) { FactoryGirl.attributes_for(:premis_event_ingest) }

    it 'returns the event when successful' do
      subject.add_event(attrs).class.should == Event
    end

    it 'returns nil if it failed' do
      subject.should_receive(:save).and_return(false)
      subject.add_event(attrs).should be_nil
    end

    it 'saves the new event to the premisEvents datastream' do
      subject.add_event(attrs)

      reload = ActiveFedora::Base.find(subject.id)
      reload.premisEvents.events.length.should == 1
      event = reload.premisEvents.events.first
      event.outcome.should == ['success']
      event.type.should == ['ingest']
      event.detail.first.should =~ /copy to s3/
    end

    it 'doesnt delete any previously exising events' do
      subject.premisEvents.events_attributes = [FactoryGirl.attributes_for(:premis_event_fixity_generation)]
      subject.save!
      subject.premisEvents.events.length.should == 1
      subject.add_event(attrs)

      reload = ActiveFedora::Base.find(subject.id)
      reload.premisEvents.events.length.should == 2
      event = reload.premisEvents.events.last
      event.outcome.should == ['success']
      event.type.should == ['ingest']
      event.detail.first.should =~ /copy to s3/
    end

    it 'writes a solr doc for the new event that includes the id of the parent object' do
      subject.save!
      event_id = '123'
      params = attrs.merge(identifier: event_id)
      subject.add_event(params)

      subject.premisEvents.events.count.should == 1
      event = subject.premisEvents.events.first

      solr_result = ActiveFedora::SolrService.query("id:#{event_id}").first
      key = "#{parent_object_key}_ssim"
      solr_result[key].should == [subject.id]
    end

  end

end
