require 'spec_helper'

describe Bag do
  before do
    @bag = FactoryGirl.create(:bag)
    @bag.save!
  end

  after do
    @bag.destroy
  end

end