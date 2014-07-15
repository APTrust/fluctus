
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
  map_predicates do |map|
    map.format(in: FileVocabulary) do |index|
      index.as :stored_sortable
    end
    map.uri(to: :absoluteURI, in: RDF::HTTP)
    map.size(in: FileVocabulary) do |index|
      index.as :stored_sortable
      index.type :integer
    end
    map.created(in: FileVocabulary)
    map.modified(in: FileVocabulary)
    map.checksum(in: FileVocabulary, class_name: "Checksum")
    map.identifier(in: RDF::DC) { |index| index.as :symbol, :stored_searchable }
  end

  accepts_nested_attributes_for :checksum
  class Checksum < ActiveFedora::RdfObject
    configure :type => RDF::DC.FileVocabulary.Checksum

    map_predicates do |map|
      map.algorithm(to: :Algorithm, in: WorldNetVocabulary)
      map.datetime(to: :created, in: RDF::DC)
      map.digest(to: :checksumValue, in: FileVocabulary)
    end
  end
end
