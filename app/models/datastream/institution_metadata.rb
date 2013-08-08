class Datastream::InstitutionMetadata < ActiveFedora::NtriplesRDFDatastream
  map_predicates do |map|
    map.name(in: RDF::DC, to: 'title') do |index|
      index.as :stored_searchable
    end
  end
end