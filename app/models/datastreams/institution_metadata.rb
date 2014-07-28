class InstitutionMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :name, predicate: RDF::DC.title do |index|
    index.as :symbol
    index.as :stored_searchable
  end
  property :brief_name, predicate: RDF::DC.alternative
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :symbol
    index.as :stored_searchable
  end
end
