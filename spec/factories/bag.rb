format = [
    {ext: "txt", type: "plain/text"},
    {ext: "xml", type: "application/xml"},
    {ext: "xml", type: "applicaiton/rdf+xml"},
    {ext: "pdf", type: "application/pdf"},
    {ext: "tif", type: "image/tiff"},
    {ext: "mp4", type: "video/mp4"},
    {ext: "wav", type: "audio/wav"},
    {ext: "pdf", type: "application/pdf"}
]

def make_file(base_uri, filename, format)
  attrs = {
    id: "#{base_uri}/#{filename}",
    format: "#{format}",
    uri: "#{base_uri}/#{filename}",
    size: rand(1000..8000),
    created: "#{Time.now}",
    modified: "#{Time.now}",
    checksum_attributes: [{
                              algorithm: "md5",
                              datetime: "#{Time.now}",
                              digest: SecureRandom.hex
                          }]
  }
end

def make_datafile(base_uri)
  format = [
      {ext: "txt", type: "plain/text"},
      {ext: "xml", type: "application/xml"},
      {ext: "xml", type: "application/rdf+xml"},
      {ext: "pdf", type: "application/pdf"},
      {ext: "tif", type: "image/tiff"},
      {ext: "mp4", type: "video/mp4"},
      {ext: "wav", type: "audio/wav"},
      {ext: "pdf", type: "application/pdf"}
  ].sample

  make_file(base_uri, "#{Faker::Lorem.characters(char_count=rand(5..15))}.#{format[:ext]}", "#{format[:type]}")
end

FactoryGirl.define do
  factory :bag do 
      description_object { FactoryGirl.create(:description_object) }
      after(:build) do |bag|
          # Fabricate a random integer for creating a PID
          i = SecureRandom.uuid

          mf = bag.fileManifest
          mf.title = "uva_uva-lib%3A#{i}"
          mf.uri = "https://s3.amazonaws.com/test_bags/uva_uva-lib%3A#{i}"

          # Generate fake bag files
          fake_files = [
              make_file(mf.uri.first, "bagit.txt", "text/plain"),
              make_file(mf.uri.first, "bag-info.txt", "text/plain"),
              make_file(mf.uri.first, "aptrust-info.txt", "text/plain"),
              make_file(mf.uri.first, "manifest-md5.txt", "text/plain"),
          ]
          rand(1..33).times { |n| fake_files << make_datafile("#{mf.uri.first}/data") }

          mf.files_attributes = fake_files

          pe = bag.premisEvents

          bag.save!

      end
  end
end
