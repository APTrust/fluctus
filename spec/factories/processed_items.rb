# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :processed_item do
    name { Faker::Lorem.word }
    etag { SecureRandom.uuid }
    bag_date { "2014-06-03 15:28:39 UTC" }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { "2014-06-03 15:28:39 UTC" }
    note { Faker::Lorem.sentence }
    action { ['Ingest', 'Fixity Check', 'Retrieval', 'Deletion'].sample }
    stage { ['Fetch', 'Unpack', 'Validate', 'Store', 'Record'].sample }
    status { ['Succeeded', 'Failed', 'Processing'].sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
    purge { false }
  end
end
