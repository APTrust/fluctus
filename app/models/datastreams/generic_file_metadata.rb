
class WorldNetVocabulary < RDF::Vocabulary("http://xmlns.com/wordnet/1.6/")
  property :Algorithm
end

class FileVocabulary < RDF::Vocabulary("http://downlode.org/Code/RDF/File_Properties/schema#")
  property :created
  property :modified
  property :size
  property :format
  property :Checksum
  property :checksum
  property :checksumValue

  property :File
end

class GenericFileMetadata < ActiveFedora::RdfxmlRDFDatastream
  #noinspection RubyArgCount
  property :format, predicate: FileVocabulary.format do |index|
    index.as :stored_sortable
  end
  property :uri, predicate: RDF::HT.absoluteURI
  property :size, predicate: FileVocabulary.size do |index|
    index.as :stored_sortable
    index.type :integer
  end
  property :created, predicate: FileVocabulary.created
  property :modified, predicate: FileVocabulary.modified
  property :checksum, predicate: FileVocabulary.checksum, class_name: 'Checksum'
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable
    index.as :symbol
  end

  accepts_nested_attributes_for :checksum
  class Checksum < ActiveFedora::Rdf::Resource
    configure :type => FileVocabulary.Checksum

    property :algorithm, predicate: WorldNetVocabulary.Algorithm
    property :datetime, predicate: RDF::DC.created
    property :digest, predicate: FileVocabulary.checksumValue
  end
end
