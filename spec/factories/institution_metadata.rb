# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :institution_metadata, class: Datastream::InstitutionMetadata do
    name { Faker::Company.name }
    brief_name { Faker::Lorem.characters rand(3..5) }
  end
end
