# Generated via
#  `rails generate active_fedora::model IntellectualObject`
class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.title(in: RDF::DC, to: 'title') do |index|
      index.as :stored_searchable
    end
    map.description(in: RDF::DC, to: 'description') do |index|
      index.as :stored_searchable
    end
    map.identifier(in: RDF::DC, to: 'identifier') do |index|
      index.as :stored_searchable
    end
    map.rights(in: RDF::DC, to: 'rights') do |index|
      index.as :stored_searchable
    end
  end
end