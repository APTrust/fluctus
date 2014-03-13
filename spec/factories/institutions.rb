FactoryGirl.define do

  sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:brief_name) { |n|  "#{Faker::Lorem.characters rand(3..4)}#{n}"}
  sequence(:identifier) { |n| "#{Faker::Internet.url} #{n}" }

  factory :institution do 
    name
    brief_name
    identifier
  end

  factory :aptrust, class: "Institution" do
    name "APTrust"
    brief_name "apt"
    identifier "aptrust"
  end
end
