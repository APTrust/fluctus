FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.build(:intellectual_object) }
    format { 'application/xml' }
    uri { 'file:///#{intellectual_object.identifier}/data/filename.xml' }
    size { rand(20000..500000000) }
    created { "#{Time.now}" }
    modified { "#{Time.now}" }

    after(:build) do  |generic_file|
      generic_file.techMetadata.checksum.build({
                     algorithm: 'md5',
                     datetime: Time.now.to_s,
                     digest: SecureRandom.hex
                 })
    end

  end

end
