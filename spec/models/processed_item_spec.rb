require 'spec_helper'

describe ProcessedItem do
  before(:all) do
    ProcessedItem.destroy_all
  end

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:etag) }
  it { should validate_presence_of(:bag_date) }
  it { should validate_presence_of(:bucket)}
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:note)}
  it { should validate_presence_of(:action) }
  it { should validate_presence_of(:stage) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:outcome) }

  it 'should properly set a name' do
    subject.name = 'Test Name'
    subject.name.should == 'Test Name'
  end

  it 'should properly set an etag' do
    subject.etag = '12345678'
    subject.etag.should == '12345678'
  end

  it 'should properly set a bag_date' do
    subject.bag_date = '2014-06-03 15:28:39 UTC'
    subject.bag_date.should == '2014-06-03 15:28:39 UTC'
  end

  it 'should properly set a bucket' do
    subject.bucket = 'aptrust.receiving.test.edu'
    subject.bucket.should == 'aptrust.receiving.test.edu'
  end

  it 'should properly set a user' do
    subject.user = 'Tim Test'
    subject.user.should == 'Tim Test'
  end

  it 'should properly set an institution' do
    subject.institution = 'test.edu'
    subject.institution.should == 'test.edu'
  end

  it 'should properly set a date' do
    subject.date = '2014-06-03 15:28:39 UTC'
    subject.date.should == '2014-06-03 15:28:39 UTC'
  end

  it 'should properly set a note' do
    subject.note = 'Malformed Bag'
    subject.note.should == 'Malformed Bag'
  end

  it 'should properly set an action' do
    subject.action = 'retry'
    subject.action.should == 'retry'
  end

  it 'should properly set a stage' do
    subject.stage = 'ingest'
    subject.stage.should == 'ingest'
  end

  it 'should properly set a status' do
    subject.status = 'Failed'
    subject.status.should == 'Failed'
  end

  it 'should properly set an outcome' do
    subject.outcome = 'Bag was not processed'
    subject.outcome.should == 'Bag was not processed'
  end

  it 'should properly set the reviewed flag' do
    subject.reviewed = false
    subject.reviewed.should == false
  end

end
