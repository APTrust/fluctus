# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :processed_item do
    name { SecureRandom.uuid + ".tar" }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { ['Ingest', 'Fixity Check', 'Retrieval', 'Deletion'].sample }
    stage { ['Fetch', 'Unpack', 'Validate', 'Store', 'Record'].sample }
    status { ['Succeeded', 'Failed', 'Processing'].sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
    purge { false }
  end
end
