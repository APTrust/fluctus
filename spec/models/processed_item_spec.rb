require 'spec_helper'

ingest = Fluctus::Application::FLUCTUS_ACTIONS['ingest']
restore = Fluctus::Application::FLUCTUS_ACTIONS['restore']
requested = Fluctus::Application::FLUCTUS_STAGES['requested']
receive = Fluctus::Application::FLUCTUS_STAGES['receive']
record = Fluctus::Application::FLUCTUS_STAGES['record']
clean = Fluctus::Application::FLUCTUS_STAGES['clean']
success = Fluctus::Application::FLUCTUS_STATUSES['success']
failed = Fluctus::Application::FLUCTUS_STATUSES['fail']
pending = Fluctus::Application::FLUCTUS_STATUSES['pend']

# Creates an item we can save. We'll set action, stage and status
# for various tests below
def setup_item(subject)
  subject.name = "sample_bag.tar"
  subject.etag = "12345"
  subject.institution = "hardknocks.edu"
  subject.bag_date = Time.now()
  subject.bucket = "aptrust.receiving.hardknocks.edu"
  subject.date = Time.now()
  subject.note = "Note"
  subject.outcome = "Outcome"
  subject.user = "user"
end

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

  it 'should say when it is not ingested' do
    subject.action = ''
    subject.ingested?.should == false

    subject.action = ingest
    subject.stage = receive
    subject.status = success
    subject.ingested?.should == false

    subject.action = ingest
    subject.stage = record
    subject.status = failed
    subject.ingested?.should == false
  end

  it 'should say when it is ingested' do
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.ingested?.should == true

    subject.stage = clean
    subject.ingested?.should == true

    subject.action = restore
    subject.stage = requested
    subject.status = pending
    subject.ingested?.should == true
  end

  it 'should NOT set object identifier in before_save if not ingested' do
    setup_item(subject)
    subject.action = ingest
    subject.stage = receive
    subject.status = success
    subject.save!
    subject.object_identifier.should == nil
  end

  it 'should set object identifier in before_save if not ingested (single part bag)' do
    setup_item(subject)
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.save!
    subject.object_identifier.should == "hardknocks.edu/sample_bag"
  end

  it 'should set object identifier in before_save if not ingested (multi part bag)' do
    setup_item(subject)
    subject.name = "sesame.street.b046.of249.tar"
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.save!
    subject.object_identifier.should == "hardknocks.edu/sesame.street"
  end


end
