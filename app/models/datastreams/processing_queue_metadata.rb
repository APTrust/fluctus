class ProcessingQueueMetadata < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
     map.table(in: RDF::DC, to: 'description') { |index| index.as :symbol, :stored_searchable }
  end
end