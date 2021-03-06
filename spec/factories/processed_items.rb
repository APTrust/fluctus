FactoryGirl.define do
  factory :processed_item, class: ProcessedItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Fluctus::Application::FLUCTUS_ACTIONS.values.sample }
    stage { Fluctus::Application::FLUCTUS_STAGES.values.sample }
    status { Fluctus::Application::FLUCTUS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
  end

  factory :ingested_item, class: ProcessedItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Fluctus::Application::FLUCTUS_ACTIONS['ingest'] }
    stage { Fluctus::Application::FLUCTUS_STAGES['record'] }
    status { Fluctus::Application::FLUCTUS_STATUSES['success'] }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
  end

  factory :processed_item_with_state, class: ProcessedItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution).pid }
    bucket { "aptrust.receiving.#{institution}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Fluctus::Application::FLUCTUS_ACTIONS.values.sample }
    stage { Fluctus::Application::FLUCTUS_STAGES.values.sample }
    status { Fluctus::Application::FLUCTUS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    reviewed { false }
    state { Faker::Lorem.sentence }
    node { Faker::Internet.ip_v4_address }
    pid { Random::rand(5000) }
  end

end
