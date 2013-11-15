FactoryGirl.define do

  factory :intellectual_object do
    title { Faker::Lorem.sentence }
    institution { FactoryGirl.create(:institution) }
  end

end