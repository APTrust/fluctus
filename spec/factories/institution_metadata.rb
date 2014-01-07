# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :institution_metadata, class: InstitutionMetadata do
    name { Faker::Company.name }
    brief_name { SecureRandom.hex(rand(3..5)) }
  end
end
