# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :processing_queue, class: ProcessingQueue do
    table { 'test' }
  end
end
