class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.title(in: RDF::DC) do |index|
      index.as :stored_searchable, :sortable
    end
    map.description(in: RDF::DC) do |index|
      index.as :stored_searchable
    end
    map.intellectual_object_identifier(in: RDF::DC, to: 'identifier') do |index|
      index.as :stored_searchable
    end
    map.rights(in: RDF::DC) do |index|
      index.as :facetable
    end
    map.institution_identifier(in: RDF::DC, to: 'relation') do |index|
      index.as :stored_searchable
    end
  end
end
