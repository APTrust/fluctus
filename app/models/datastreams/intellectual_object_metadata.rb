class IntellectualObjectMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :title, predicate: RDF::DC.title do |index|
    index.as :sortable
    index.as :stored_searchable
  end
  property :description, predicate: RDF::DC.description do |index|
    index.as :stored_searchable
  end
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable
    index.as :symbol
  end
  property :alt_identifier, predicate: RDF::DC11.identifier do |index|
    index.as :stored_searchable
  end
  property :access, predicate: RDF::DC.rights do |index|
    index.as :facetable
  end
end
