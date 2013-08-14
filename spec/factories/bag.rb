FactoryGirl.define do
  factory :bag do 
    description_object { FactoryGirl.create(:description_object) }
    after(:build) {|bag|
      # Fabricate a random integer for creating a PID
      i = rand(100000000)

      mf = bag.fileManifest
      mf.title = "uva_uva-lib_#{i}"
      mf.uri = "https://s3.amazonaws.com/test_bags/uva_uva-lib%3A#{i}"
      (1..10).to_a.sample.times do |index|
        # Get a sample MIME type for a particular File.
        format = ['application/xml', 'application/rdf+xml', 'image/tiff', 'video/mp4'].sample

        bag.fileManifest.files.build
        bag.fileManifest.files[index - 1].format = "#{format}"
        bag.fileManifest.files[index - 1].uri = "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_#{i}/bagit.txt"
        bag.fileManifest.files[index - 1].size = "#{(0..10000).to_a.sample}"
        bag.fileManifest.files[index - 1].created = "#{Time.now}"
        bag.fileManifest.files[index - 1].modified = "#{Time.now}"
        bag.fileManifest.files[index - 1].checksum.build
        bag.fileManifest.files[index - 1].checksum.first.algorithm = "md5"
        bag.fileManifest.files[index - 1].checksum.first.datetime = "#{Time.now}"
        bag.fileManifest.files[index - 1].checksum.first.digest = SecureRandom.hex
      end
      bag.save!
    }
  end
end
