module Hydra::Queue
  extend ActiveSupport::Autoload
  autoload :Resque
  def self.config
      @@config ||= Configuration.new
      yield @@config if block_given?
      return @@config
  end

  def self.push(val)
    instance.push(val)
  end

  private 
  def self.instance
    @@instance ||= config.queue.new('fluctus')
  end

  class Configuration
    mattr_accessor :queue
  end
end
