FactoryGirl.define do

  factory :generic_file do
    intellectual_object { FactoryGirl.create(:intellectual_object) }
    # descMetadata { FactoryGirl.create(:generic_file_desc_metadata)}
  end

end