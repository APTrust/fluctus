class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :title, predicate: RDF::DC.title do |index|
    index.as :stored_searchable, :sortable
  end
  property :description, predicate: RDF::DC.description do |index|
    index.as :stored_searchable
  end
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable, :symbol, :stored_sortable, :facetable
  end
  property :alt_identifier, predicate: RDF::DC11.identifier do |index|
    index.as :stored_searchable, :symbol
  end
  property :access, predicate: RDF::DC.rights do |index|
    index.as :facetable
  end
  property :bag_name, predicate: RDF::DC.alternative do |index|
    index.as :stored_searchable, :symbol
  end
end
