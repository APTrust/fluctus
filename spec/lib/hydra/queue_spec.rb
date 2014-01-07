require 'spec_helper'

describe Hydra::Queue do
  class TestJob
    class_attribute :worked
    attr_accessor :name

    def initialize(name)
      self.name = name
    end

    def run
      self.class.worked = name
    end
  end
  it "should do work in the background" do
    Hydra::Queue.push TestJob.new('test message')
    TestJob.worked.should == 'test message'

  end
end
