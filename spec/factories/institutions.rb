FactoryGirl.define do

  sequence(:title) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:brief_name) { |n|  "#{Faker::Lorem.characters rand(3..4)}#{n}"}
  sequence(:identifier) { |n| "#{n}#{Faker::Internet.domain_word}.com"}

  factory :institution do 
    title
    brief_name
    identifier
  end

  factory :aptrust, class: "Institution" do
    title "APTrust"
    brief_name "apt"
    identifier "aptrust.org"
  end
end
