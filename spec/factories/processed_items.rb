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
    action { Fluctus::Application::PROC_ITEM_ACTIONS.sample }
    stage { Fluctus::Application::PROC_ITEM_STAGES.sample }
    status { Fluctus::Application::PROC_ITEM_STATUSES.sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
  end

  factory :ingested_item, class: "ProcessedItem" do
    name { SecureRandom.uuid + ".tar" }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { 'Ingest' }
    stage { 'Record' }
    status { 'Succeeded' }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
  end

end
