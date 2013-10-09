class Datastream::InstitutionMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.name(in: RDF::DC, to: 'title') { |index| index.as :stored_searchable }
    map.brief_name(in: RDF::DC, to: 'alternative')
  end
end