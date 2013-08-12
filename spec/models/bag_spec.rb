require 'spec_helper'

describe Bag do
  before do
    @bag = Bag.new
    mf = @bag.fileManifest
    mf.title = "uva_uva-lib%3A744861"
    mf.uri = "https://s3.amazonaws.com/test_bags/uva_uva-lib%3A744861"
    mf.files.build(
        format: "text/plain",
        type: "textfile",
        uri: "/test_bags/uva_uva-lib%3A744861/bagit.txt",
        size: 3456,
        created: "#{Time.now}",
        modified: "#{Time.now}",
        checksum_attributes: {
            algorithm: "md5",
            datetime: "#{Time.now}",
            digest: "ada799b7e0f1b7a1dc86d4e99df4b1f4"
        }
    )
    @bag.save
  end

  after do
    @bag.destroy
  end

  it 'should return the original pid' do
    @bag.parse_pid.should == "uva-lib:744861"
  end
end