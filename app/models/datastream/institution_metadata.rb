class Datastream::InstitutionMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "institution")
    t.name(index_as: :stored_searchable)
    t.contacts {
      t.name
      t.email
    }    
  end

  def self.xml_template
    Nokogiri::XML.parse("<institution/>")
  end
end