# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :generic_file_tech_metadata, :class => 'GenericFileMetadata' do
    format { 'application/xml' }
    uri { 'test/data/filename.xml' }
    size { rand(20000..500000000) }
    created { "#{Time.now}" }
    modified { "#{Time.now}" }
    checksum_attributes {
      [{
           algorithm: 'md5',
           datetime: Time.now.to_s,
           digest: SecureRandom.hex
       }]
    }
  end
end