class Datastream::CompressedBagMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: 'compressed_bag')
    t.title(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<compressed_bag/>")
  end
end