require 'spec_helper'

describe Datastream::PremisEvent do

  before do
      @bag = Bag.new
  end

  it 'should create a valid event' do
    pe = @bag.premisEvents
    pe.events.build(
        identifier: "0hc50321-6d7b-3847-89ag-a8b0fhc1f245",
        type: "fixity generation",
        date_time: "2010-08-01T09:08:46-01:00",
        outcome_detail: "",
        outcome_infromation: "454c167687fc3ce46e48b62533ea70e804287c413683158c58d49f23fcca397d",
        object: "binary_object_identifier",
        agent: "Amazon S3 fixity generator"
    )

  end
end