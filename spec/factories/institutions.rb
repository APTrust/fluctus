# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :aptrust, class: "Institution" do
    name "APTrust"
  end

  factory :fake_university, class: "Institution" do
    name "Fake University"
  end

  factory :institution do 
    name { Faker::Company.name }
  end
end
