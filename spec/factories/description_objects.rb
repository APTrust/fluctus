# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :description_object do
    title Faker::Commerce.product_name
    institution
  end
end
