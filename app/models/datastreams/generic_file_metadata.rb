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
  property :file_format
  property :Checksum
  property :checksum
  property :checksumValue

  property :File
end

class GenericFileMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :file_format, predicate: FileVocabulary.file_format do |index|
    index.as :stored_sortable
  end
  property :uri, predicate: RDF::HT.absoluteURI do |index|
    index.as :symbol
  end
  property :file_size, predicate: FileVocabulary.size do |index|
    index.as :sortable_long
  end
  property :created, predicate: FileVocabulary.created do |index|
    index.as :symbol
  end
  property :modified, predicate: FileVocabulary.modified do |index|
    index.as :symbol
  end
  property :file_checksum, predicate: FileVocabulary.checksum, class_name: 'Checksum'
  property :identifier, predicate: RDF::DC.identifier do |index|
    index.as :stored_searchable, :symbol
  end

  accepts_nested_attributes_for :file_checksum
  class Checksum < ActiveTriples::Resource
    include ActiveFedora::RDF::Persistence
    configure :type => FileVocabulary.Checksum

    property :algorithm, predicate: WorldNetVocabulary.Algorithm do |index|
      index.as :symbol
    end
    property :datetime, predicate: RDF::DC.created do |index|
      index.as :symbol
    end
    property :digest, predicate: FileVocabulary.checksumValue do |index|
      index.as :symbol
    end
  end
end
