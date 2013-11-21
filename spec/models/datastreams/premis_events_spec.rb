require 'spec_helper'

# NOTE basing tests on examples found at
# https://github.com/anusharanganathan/oraingest/blob/master/spec/models/datastreams/workflow_rdf_datastream_spec.rb
describe PremisEventsMetadata do

  subject { PremisEventsMetadata.new(double('inner object', pid: 'test/pexxx34234', :new? => true), 'premisEvents')}

  before do
    @e_fix = subject.events.build(
        type: "fixity generation",
        date_time: "#{Time.now}",
        detail:  "S3 fixity check",
        outcome_detail: "",
        outcome_information: "454c167687fc3ce46e48b62533ea70e804287c413683158c58d49f23fcca397d",
        object: "bag_id/data/pathtoitem.item",
        agent: "Amazon S3 Fixity App"
    )
    subject.events.build(
        type: "Bag Creation",
        date_time: Time.now,
        detail: "Bag created with service.",
        outcome: "this is my outcome",
        outcome_detail: "",
        outcome_information: "",
        object: "bag_id",
        agent: "Golang Bag Script"
    )
  end

  it 'should contain events' do
    subject.should.respond_to? :events
    subject.events.count.should == 2
  end

  it "should have a proper fixity event" do

    @e_fix.date_time.should_not be_empty
    @e_fix.detail.should == ["S3 fixity check"]
    @e_fix.outcome_detail.should == [""]
    @e_fix.outcome_information.should == ["454c167687fc3ce46e48b62533ea70e804287c413683158c58d49f23fcca397d"]
    @e_fix.object.should == ["bag_id/data/pathtoitem.item"]
    @e_fix.agent.should == ["Amazon S3 Fixity App"]
  end

end