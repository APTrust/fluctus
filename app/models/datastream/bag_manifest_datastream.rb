# NOTE using terms from https://github.com/bendiken/rdf/blob/master/lib/rdf/vocab/dc.rb
# where possible

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

class Datastream::BagManifestDatastream < ActiveFedora::NtriplesRDFDatastream

  # NOTE this does not get the line include ActiveFedora::RdfObject
  #      because it is a subclass of something that calls it already

  map_predicates do |map|
    map.title(in: RDF::DC)
    map.uri(to: :absoluteURI, in: RDF::HTTP)
    map.files(to: :File, in: FileVocabulary, class_name: "BagFile")
  end

  accepts_nested_attributes_for :files

end

class BagFile
  include ActiveFedora::RdfObject

  map_predicates do |map|
    #map.creator(in: RDF::DC)
    map.format(in: FileVocabulary)
    map.type(in: RDF::DC)
    map.uri(to: :absoluteURI, in: RDF::HTTP)
    map.size(in: FileVocabulary)
    map.created(in: FileVocabulary)
    map.modified(in: FileVocabulary)
    map.checksum(in: FileVocabulary, class_name: "Checksum")
  end

  accepts_nested_attributes_for :checksum
end

class Checksum
  include ActiveFedora::RdfObject

  rdf_type FileVocabulary.Checksum

  map_predicates do |map|
    map.algorithm(to: :Algorithm, in: WorldNetVocabulary)
    map.datetime(to: :created, in: RDF::DC)
    map.digest(to: :checksumValue, in: FileVocabulary)
  end
end


#f.checksum.build(checksumValue: "nnval", generator_attributes: {algorithm: "URI"})

# cs = b.files.first.checksum.first
# cs.algorithm
# cs.datetime
# cs.value
#
#f = b.files.build(...)
#f.checksum.build(algorithm: "foo" )
#OR
#
#f = b.files.build(checksum_attributes: {algorithm: "foo", checksum_value: "blah"})
#
#b = bds.files.build({format: "floo", checksum_attributes: {algorithm: "foo", checksum_value: "blah"}})
#
#b = bds.files_attributes = [{format: "floo", checksum_attributes: {algorithm: "foo", checksum_value: "blah"}}]