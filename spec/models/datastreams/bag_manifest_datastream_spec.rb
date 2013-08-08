require 'spec_helper'

describe Datastream::BagManifestDatastream do

  before do
    bag = Bag.new
    @mf = bag.fileManifest
    @mf.title = "uva_uva_lib_1229365"
    @mf.uri = "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"
    @fi1 = @mf.files.build(
      format: "text/plain",
      type: "textfile",
      uri: "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt",
      size: 3456,
      created: "#{Time.now}",
      modified: "#{Time.now}",
      checksum_attributes: {
          algorithm: "md5",
          datetime: "#{Time.now}",
          digest: "ada799b7e0f1b7a1dc86d4e99df4b1f4"
      }
    )
  end

  it 'should contain top level properties' do
    @mf.title.should == ["mybagtitle"]
    @mf.files.count.should == 1
    @mf.uri.should == ["http://www.webstuff.com/mybagtitle"]
  end
end