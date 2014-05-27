class ProcessingQueue < ActiveFedora::Base

  has_metadata "queueMetadata", type: ProcessingQueueMetadata
  has_attributes :table, datastream: 'queueMetadata', multiple: false
  validates :table, presence: true

end
