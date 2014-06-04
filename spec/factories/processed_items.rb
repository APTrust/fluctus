# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :processed_item do
    name { Faker::Lorem.word }
    etag { SecureRandom.uuid }
    bag_date { Faker::Number.number(8) }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Faker::Number.number(4) }
    note { Faker::Lorem.sentence }
    action { Faker::Lorem.word }
    stage { Faker::Lorem.word }
    status { ["Succeeded", "Failed", "Processing"].sample }
    outcome { Faker::Lorem.sentence }
  end
end
