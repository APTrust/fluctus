FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.create(:intellectual_object) }
    format { 'application/xml' }
    uri { 'test/data/filename.xml' }
    size { rand(20000..500000000) }
    created { "#{Time.now}" }
    modified { "#{Time.now}" }

    before(:create) do  |generic_file|
      generic_file.descMetadata.checksum.build({
                     algorithm: 'md5',
                     datetime: Time.now.to_s,
                     digest: SecureRandom.hex
                 })
    end

  end



end