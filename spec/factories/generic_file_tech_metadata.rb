# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence(:uri) { |n| "#file:///#{intellectual_object.identifier}/data/#{n}filename.xml" }

  factory :generic_file_tech_metadata, :class => 'GenericFileMetadata' do
    file_format { 'application/xml' }
    identifier { "virginia.edu.#{self.intellectual_object.identifier}/data/#{n}filename.xml" }
    uri
    size { rand(20000..500000000) }
    created { "#{Time.now}" }
    modified { "#{Time.now}" }
    checksum_attributes {
      [{
           algorithm: 'sha256',
           datetime: Time.now.to_s,
           digest: SecureRandom.hex
       }]
    }
  end

end