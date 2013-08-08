class Datastream::InstitutionMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.name(in: RDF::DC, to: 'title') do |index|
      index.as :stored_searchable
    end
  end
end