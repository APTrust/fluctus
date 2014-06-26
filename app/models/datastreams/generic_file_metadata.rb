
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
  property :md5
  property :Md5
  property :sha256
  property :Sha256

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
    map.md5(in: FileVocabulary, class_name: "Md5")
    map.sha256(in: FileVocabulary, class_name: "Sha256")
    map.identifier(in: RDF::DC) { |index| index.as :symbol, :stored_searchable }
  end

  accepts_nested_attributes_for :md5
  class Md5
    include ActiveFedora::RdfObject

    rdf_type FileVocabulary.Md5

    map_predicates do |map|
      map.algorithm(to: :Algorithm, in: WorldNetVocabulary)
      map.datetime(to: :created, in: RDF::DC)
      map.digest(to: :checksumValue, in: FileVocabulary)
    end
  end

  accepts_nested_attributes_for :sha256
  class Sha256
    include ActiveFedora::RdfObject

    rdf_type FileVocabulary.Sha256

    map_predicates do |map|
      map.algorithm(to: :Algorithm, in: WorldNetVocabulary)
      map.datetime(to: :created, in: RDF::DC)
      map.digest(to: :checksumValue, in: FileVocabulary)
    end
  end
end
