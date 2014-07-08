class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.title(in: RDF::DC) do |index|
      index.as :stored_searchable, :sortable
    end
    map.description(in: RDF::DC) do |index|
      index.as :stored_searchable
    end
    map.identifier(in: RDF::DC, to: 'relation') do |index|
      index.as :symbol, :stored_searchable
    end
    map.alt_identifier(in: RDF::DC, to: 'identifier') do |index|
      index.as :stored_searchable
    end
    map.access(in: RDF::DC, to: 'rights') do |index|
      index.as :facetable
    end
  end
end
