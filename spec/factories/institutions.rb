FactoryGirl.define do

  sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:brief_name) { |n|  "#{Faker::Lorem.characters rand(3..4)}#{n}"}
  sequence(:institution_identifier) { |n| "#{Faker::Internet.domain_name}#{n}" }

  factory :institution do 
    name
    brief_name
    institution_identifier
  end

  factory :aptrust, class: "Institution" do
    name "APTrust"
    brief_name "apt"
    institution_identifier "aptrust.org"
  end
end
