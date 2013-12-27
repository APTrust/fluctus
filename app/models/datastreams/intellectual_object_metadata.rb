class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.title(in: RDF::DC) do |index|
      index.as :stored_searchable, :sortable
    end
    map.description(in: RDF::DC) do |index|
      index.as :stored_searchable
    end
    map.identifier(in: RDF::DC) do |index|
      index.as :stored_searchable
    end
    map.rights(in: RDF::DC) do |index|
      index.as :facetable
    end
  end
end
