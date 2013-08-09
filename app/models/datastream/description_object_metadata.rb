class Datastream::DescriptionObjectMetadata < ActiveFedora::NtriplesRDFDatastream
  map_predicates do |map|
    map.title(in: RDF::DC, to: 'title') do |index|
      index.as :stored_searchable
    end
  end
end