FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.build(:intellectual_object) }
    identifier { "#{intellectual_object.identifier}/data/filename.xml" }
    file_format { 'application/xml' }
    uri { 'file://test/data/filename.xml' }
    size { rand(20000..500000000) }
    created { "#{Time.now}" }
    modified { "#{Time.now}" }
    generic_file_identifier { "#{intellectual_object.intellectual_object_identifier}/data/filename.xml" }

    after(:build) do  |generic_file|
      generic_file.techMetadata.checksum.build({
                     algorithm: 'md5',
                     datetime: Time.now.to_s,
                     digest: SecureRandom.hex
                 })
    end

  end

end
