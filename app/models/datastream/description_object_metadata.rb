class Datastream::DescriptionObjectMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: 'object')
    t.title
    t.dpn_status
  end

  def self.xml_template
    Nokogiri::XML.parse("<object/>")
  end
end