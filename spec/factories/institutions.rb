# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :institution do
    name Faker::Company.name
  end
end
