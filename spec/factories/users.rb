FactoryGirl.define do
  factory :user, class: "User" do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    institution_pid { FactoryGirl.create(:institution).pid }
  
    factory :aptrust_user, class: "User" do
      institution_pid { 
        relation = Institution.where(desc_metadata__name_tesim: 'APTrust')
        if relation.count == 1
          relation.first.pid
        else
          FactoryGirl.create(:aptrust).pid
        end
      }
    end

    trait :admin do
      roles { [Role.where(name: 'admin').first] }
    end

    trait :institutional_admin do
      roles { [Role.where(name: 'institutional_admin').first] }
    end

    trait :institutional_user do
      roles { [Role.where(name: 'institutional_user').first] }
    end
  end
end
