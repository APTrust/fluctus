# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :description_object do
    title { Faker::Lorem.sentence }
    institution { FactoryGirl.create(:institution) }
  end

end
