FactoryGirl.define do
  factory :bag do 
    description_object { FactoryGirl.create(:description_object) }
    after(:build) {|bag|
      # Fabricate a random integer for creating a PID
      i = rand(100000000)

      @fm = bag.fileManifest
      @fm.title = "uva_uva-lib%3A#{i}"
      @fm.uri = "https://s3.amazonaws.com/test_bags/uva_uva-lib%3A#{i}"
      @files_attributes = []
      (1..10).to_a.sample.times do
        n = rand(100000000)
        # Get a sample MIME type for a particular File.
        format = ['application/xml', 'application/rdf+xml', 'image/tiff', 'video/mp4'].sample
        @files_attributes << {
          id: "#{@fm.uri.first}/datastream_#{n}",
          format: "#{format}",
          uri: "#{@fm.uri.first}/datastream_#{n}",
          size: "#{(0..10000).to_a.sample}",
          created: "#{Time.now}",
          modified: "#{Time.now}",
          checksum_attributes: [{
            algorithm: "md5",
            datetime: "#{Time.now}",
            digest: SecureRandom.hex
          }]
        }
      end
      @fm.files_attributes = @files_attributes
      bag.save!
      bag.description_object.save!
    }
  end
end
