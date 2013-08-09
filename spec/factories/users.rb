# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user, class: "User" do
    name Faker::Name.name
    email Faker::Internet.email
    phone_number Faker::PhoneNumber.phone_number
    institution_name "Fake University"
  
    factory :aptrust_user, class: "User" do
      institution_name "APTrust"
    end
  end
end
