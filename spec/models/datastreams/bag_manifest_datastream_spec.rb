require 'spec_helper'

describe BagManifestDatastream do

  before do
    bag = Bag.new
    @mf = bag.fileManifest
    # @mf.id = "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"
    @mf.title = "uva_uva_lib_1229365"
    @mf.uri = "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"
    @mf.files_attributes = [{
        id: "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt",
        format: "text/plain",
        uri: "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt",
        size: 3456,
        created: "#{Time.now}",
        modified: "#{Time.now}",
        checksum_attributes: [{
          algorithm: "md5",
          datetime: "#{Time.now}",
          digest: "ada799b7e0f1b7a1dc86d4e99df4b1f4"
        }]
        },
        {
        id: "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bag-info.txt",
        format: "text/plain",
        uri: "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bag-info.txt",
        size: 3456,
        created: "#{Time.now}",
        modified: "#{Time.now}",
        checksum_attributes: [{
            algorithm: "md5",
            datetime: "#{Time.now}",
            digest: "cbc799b7e0f1b7a1dc86d4e99df4b2f6"
        }]
    }]
  end

  it 'should have a proper rdf_subject for a file' do
    @mf.files.first.rdf_subject.to_s.should == "https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt"
  end

  it 'should have properties and files' do
    @mf.title.should == ["uva_uva_lib_1229365"]
    @mf.files.count.should == 2
    @mf.uri.should == ["https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365"]
  end

  it "should have valid file properties" do
    @mf.files.first.format.should == ["text/plain"]
    @mf.files.first.uri.should == ["https://s3.amazonaws.com/aptrust_test_bags/uva_uva_lib_1229365/bagit.txt"]
    @mf.files.first.size.should == ["3456"]
    @mf.files.first.checksum.count.should == 1
    @mf.files.first.created.should_not be_empty
    @mf.files.first.modified.should_not be_empty
  end

  it "should have valid checksum properties" do
    @mf.files.first.checksum.first.algorithm.should == ["md5"]
    @mf.files.first.checksum.first.datetime.should_not be_empty
    @mf.files.first.checksum.first.digest.should == ["ada799b7e0f1b7a1dc86d4e99df4b1f4"]
  end
end