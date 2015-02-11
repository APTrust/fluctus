class InstitutionMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :title, predicate: RDF::DC.title do |index|
    index.as :stored_searchable, :symbol
  end
  property :brief_name, predicate: RDF::DC.alternative do |index|
    index.as :symbol
  end
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable, :symbol
  end
end
