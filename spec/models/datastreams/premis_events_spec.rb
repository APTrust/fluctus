require 'spec_helper'

# NOTE basing tests on examples found at
# https://github.com/anusharanganathan/oraingest/blob/master/spec/models/datastreams/workflow_rdf_datastream_spec.rb
describe PremisEventsMetadata do

  subject { PremisEventsMetadata.new(double('inner object', pid: 'test/pexxx34234', :new_record? => true), 'premisEvents')}

  before do
    @e_fix = subject.events.build(
        identifier: '123',
        type: 'fixity generation',
        date_time: "#{Time.now}",
        detail:  'S3 fixity check',
        outcome: 'success',
        outcome_detail: '',
        outcome_information: '454c167687fc3ce46e48b62533ea70e804287c413683158c58d49f23fcca397d',
        object: 'bag_id/data/pathtoitem.item',
        agent: 'Amazon S3 Fixity App'
    )
    subject.events.build(
        type: 'Bag Creation',
        date_time: Time.now,
        detail: 'Bag created with service.',
        outcome: 'this is my outcome',
        outcome_detail: '',
        outcome_information: '',
        object: 'bag_id',
        agent: 'Golang Bag Script'
    )
  end

  it 'should contain events' do
    subject.should.respond_to? :events
    subject.events.count.should == 2
  end

  it 'should have a proper fixity event' do
    @e_fix.identifier.should == ['123']
    @e_fix.date_time.should_not be_empty
    @e_fix.detail.should == ['S3 fixity check']
    @e_fix.outcome.should == ['success']
    @e_fix.outcome_detail.should == ['']
    @e_fix.outcome_information.should == ['454c167687fc3ce46e48b62533ea70e804287c413683158c58d49f23fcca397d']
    @e_fix.object.should == ['bag_id/data/pathtoitem.item']
    @e_fix.agent.should == ['Amazon S3 Fixity App']
  end

  it 'creates a UUID if no identifier is passed in' do
    stub_id = 'abcdefg'
    #UUIDTools::UUID.should_receive(:timestamp_create).and_return(stub_id)
    SecureRandom.should_receive(:uuid).and_return(stub_id)

    attrs = FactoryGirl.attributes_for(:premis_event_fixity_generation)
    attrs[:identifier].should be_nil  # Pass in nil identifier

    event = subject.events.build(attrs)
    event.identifier.should == [stub_id]
  end

end


describe Event do

  let(:attrs) { FactoryGirl.attributes_for(:premis_event_fixity_generation).merge(identifier: '123') }
  let(:meta) { PremisEventsMetadata.new(double('inner object', pid: 'test/pexxx34234', :new_record? => true), 'premisEvents')}

  describe '#to_solr' do
    it 'contains the fields needed for search, sort, display' do
      event = meta.events.build(attrs)
      event.to_solr['id'].should == attrs[:identifier]
      event.to_solr['event_type_ssim'].should == [attrs[:type]]
      event.to_solr['event_outcome_ssim'].should == [attrs[:outcome]]
      event.to_solr['event_date_time_si'].should == attrs[:date_time]
      event.to_solr['event_date_time_ssim'].should == [attrs[:date_time]]
    end
  end

end
