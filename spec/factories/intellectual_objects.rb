FactoryGirl.define do

  factory :intellectual_object, class: IntellectualObject do
    institution { FactoryGirl.create(:institution) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    intellectual_object_identifier { "#{SecureRandom.uuid}" }
    rights { ['consortial', 'institution', 'restricted'].sample }

    factory :consortial_intellectual_object, class: IntellectualObject do
      rights { 'consortial' }
    end

    factory :institutional_intellectual_object, class: IntellectualObject do
      rights { 'institution' }
    end

    factory :restricted_intellectual_object, class: IntellectualObject do
      rights { 'restricted' }
    end

  end

end