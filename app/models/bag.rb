class Bag < ActiveFedora::Base
  has_metadata 'descMetadata', type: Datastream::BagMetadata
  has_metadata 'premisEvents', type: Datastream::PremisEventDatastream
  has_metadata 'fileManifest', type: Datastream::BagManifestDatastream

  belongs_to :description_object, property: :is_part_of

  # This method is being stashed until we determine the relationship 
  # between bags and compressed bags.
  #
  # validate :validate_compressed_bag_count

  # # A Bag object should only have one associated CompressedBag.  ActiveFedora (as of version 6.4)
  # # does not have a 'has_one' relationship.  Therefore we are forced to create a validation to enforce
  # # the singularity of that relationship.
  # def validate_compressed_bag_count
  #   if self.compressed_bags.count > 1
  #     errors.add('A bag cannot have more than 1 associated CompressedBag.')
  #   end
  # end

  # Parses the original pid value for this object as a convienence method.
  def parse_pid
    title = self.fileManifest.title[0]
    if title
      URI.unescape(title.gsub(/\w*_/, ""))
    end
  end
end