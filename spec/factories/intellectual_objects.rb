FactoryGirl.define do

  factory :intellectual_object, class: IntellectualObject do
    institution { FactoryGirl.create(:institution) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    identifier { SecureRandom.uuid }
    rights { ['public', 'institution', 'private'].sample }
  end

end