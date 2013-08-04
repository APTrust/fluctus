# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    name Faker::Name.name
    email Faker::Internet.email
    phone_number Faker::PhoneNumber.phone_number
    institution_name FactoryGirl.create(:institution).name
  end
end
