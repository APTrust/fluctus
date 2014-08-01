# This file defines the GenericFile datastream, but first we
# have to add a long-stored-indexed type to Solrizer, or we
# won't be able to store size info about files larger than 2GB.
# TODO: Move this?
module Solrizer
  module DefaultDescriptors
    def self.sortable_long
      Solrizer::SortableLongDescriptor.new(:long, :stored, :indexed)
    end
  end

  class SortableLongDescriptor < Solrizer::Descriptor
    def name_and_converter(field_name, field_type)
        [field_name + '_lsi']
    end
    protected
    def suffix(field_type)
      [field_name + '_lsi']
    end
  end
end

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
    index.as :sortable_long
  end
  property :created, predicate: FileVocabulary.created
  property :modified, predicate: FileVocabulary.modified
  property :checksum, predicate: FileVocabulary.checksum, class_name: 'Checksum'
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable, :symbol
  end

  accepts_nested_attributes_for :checksum
  class Checksum < ActiveFedora::Rdf::Resource
    configure :type => FileVocabulary.Checksum

    property :algorithm, predicate: WorldNetVocabulary.Algorithm
    property :datetime, predicate: RDF::DC.created
    property :digest, predicate: FileVocabulary.checksumValue
  end
end
