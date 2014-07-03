# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :processed_item do
    name { Faker::Lorem.word }
    etag { SecureRandom.uuid }
    bag_date { Time.now }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now }
    note { Faker::Lorem.sentence }
    action { ['Ingest', 'Fixity Check', 'Retrieval', 'Deletion'].sample }
    stage { ['Fetch', 'Unpack', 'Validate', 'Store', 'Record'].sample }
    status { ['Succeeded', 'Failed', 'Processing'].sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
    purge { false }
  end
end
