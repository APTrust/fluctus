FactoryGirl.define do

  factory :institution do 
    name { Faker::Company.name }
    brief_name {  Faker::Lorem.characters rand(3..5) }
  end

  factory :aptrust, class: "Institution" do
    name "APTrust"
    brief_name "apt"
  end
end
