FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.create(:intellectual_object) }
  end

end