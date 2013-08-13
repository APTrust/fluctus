FactoryGirl.define do
  factory :institution do 
    name { Faker::Company.name }
  end

  factory :aptrust, class: "Institution" do
    name "APTrust"
  end
end
