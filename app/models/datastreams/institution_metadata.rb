class InstitutionMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.name(in: RDF::DC, to: 'title') { |index| index.as :symbol, :stored_searchable }
    map.brief_name(in: RDF::DC, to: 'alternative')
    map.identifier(in: RDF::DC) do |index|
      index.as :symbol, :stored_searchable
    end
  end
end
