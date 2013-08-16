require 'spec_helper'

describe Bag do
  before do
    @bag = FactoryGirl.create(:bag)
    @bag.fileManifest.title = "uva_uva-lib%3A744861"
    @bag.save!
  end

  after do
    @bag.destroy
  end

  it 'should return the original pid' do
    @bag.parse_pid.should == "uva-lib:744861"
  end
end