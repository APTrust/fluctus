FactoryGirl.define do

  factory :intellectual_object, class: IntellectualObject do
    institution { FactoryGirl.create(:institution) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    identifier { SecureRandom.uuid }
    rights { ['public', 'institution', 'private'].sample }

    factory :public_intellectual_object, class: IntellectualObject do
      rights { 'public' }
    end

    factory :institutional_intellectual_object, class: IntellectualObject do
      rights { 'institution' }
    end

    factory :private_intellectual_object, class: IntellectualObject do
      rights { 'private' }
    end

  end



end