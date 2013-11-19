class BagMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: 'bag')
    t.title(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<bag/>")
  end
end