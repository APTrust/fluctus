class Datastream::DescriptionObjectMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: 'object')
    t.title(index_as: :stored_searchable)
    t.dpn_status(index_as: [:facetable, :stored_searchable])
  end

  def self.xml_template
    Nokogiri::XML.parse("<object/>")
  end
end