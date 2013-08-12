require 'spec_helper'

describe Datastream::BagManifestDatastream do

  before do
    bag = Bag.new
    @mf = bag.fileManifest
    @mf.title = "uva_uva_lib_1229365"
    @mf.uri = "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"
    @fi = @mf.files.build(
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

  it 'should have properties and files' do
    @mf.title.should == ["uva_uva_lib_1229365"]
    @mf.files.count.should == 1
    @mf.uri.should == ["https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"]
  end

  it "should have valid file properties" do
    @fi.format.should == ["text/plain"]
    @fi.uri.should == ["https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt"]
    @fi.size.should == ["3456"]
    @fi.checksum.count.should == 1
    @fi.created.should_not be_empty
    @fi.modified.should_not be_empty
  end

  it "should have valid checksum properties" do
    @fi.checksum.first.algorithm.should == ["md5"]
    @fi.checksum.first.datetime.should_not be_empty
    @fi.checksum.first.digest.should == ["ada799b7e0f1b7a1dc86d4e99df4b1f4"]
  end
end