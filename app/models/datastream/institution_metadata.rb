class Datastream::InstitutionMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "institution")
    t.name(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<institution/>")
  end
end