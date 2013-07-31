# Override the default attributes of ActiveFedora::RelsExtDatastream so that the mimeType
# is text/xml (which opens in the browser).  I have no idea why the hardcoded default is 'application/rdf+xml'.
module ActiveFedora
  class RelsExtDatastream < Datastream
    def self.default_attributes
      super.merge(:controlGroup => 'X', :mimeType => 'text/xml')
    end
  end
end