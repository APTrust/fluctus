FactoryGirl.define do

  sequence(:title) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:brief_name) { |n|  "#{Faker::Lorem.characters rand(3..4)}#{n}"}
  sequence(:identifier) { |n| "#{n}#{Faker::Internet.domain_word}.com"}
  sequence(:dpn_uuid) { |n| "#{n}#{SecureRandom.uuid}"}

  factory :institution do 
    title
    brief_name
    identifier
    dpn_uuid
  end

  factory :aptrust, class: 'Institution' do
    title 'APTrust'
    brief_name 'apt'
    identifier 'aptrust.org'
    dpn_uuid ''
  end
end
