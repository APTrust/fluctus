FactoryGirl.define do

  factory :intellectual_object, class: IntellectualObject do
    institution { FactoryGirl.create(:institution) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    identifier { "#{institution.identifier}/#{institution.identifier}.spectator_1961-#{rand(12)}-#{rand(31)}_001" }
    access { ['consortia', 'institution', 'restricted'].sample }
    alt_identifier { [] }
    bag_name { identifier.split("/")[1] }

    factory :consortial_intellectual_object, class: IntellectualObject do
      access { 'consortia' }
    end

    factory :institutional_intellectual_object, class: IntellectualObject do
      access { 'institution' }
    end

    factory :restricted_intellectual_object, class: IntellectualObject do
      access { 'restricted' }
    end

  end
end
