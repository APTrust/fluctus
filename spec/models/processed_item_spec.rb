require 'spec_helper'

ingest = Fluctus::Application::FLUCTUS_ACTIONS['ingest']
restore = Fluctus::Application::FLUCTUS_ACTIONS['restore']
dpn = Fluctus::Application::FLUCTUS_ACTIONS['dpn']
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
  subject.name = 'sample_bag.tar'
  subject.etag = '12345'
  subject.institution = 'hardknocks.edu'
  subject.bag_date = Time.now()
  subject.bucket = 'aptrust.receiving.hardknocks.edu'
  subject.date = Time.now()
  subject.note = 'Note'
  subject.outcome = 'Outcome'
  subject.user = 'user'
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
    subject.object_identifier.should == 'hardknocks.edu/sample_bag'
  end

  it 'should set object identifier in before_save if not ingested (multi part bag)' do
    setup_item(subject)
    subject.name = 'sesame.street.b046.of249.tar'
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.save!
    subject.object_identifier.should == 'hardknocks.edu/sesame.street'
  end

  it 'should set queue state fields' do
    ts = Time.now
    setup_item(subject)
    subject.action = ingest
    subject.stage = record
    subject.status = pending
    subject.state = '{ some: "blob", of: "json" }'
    subject.node = "10.11.12.13"
    subject.pid = 808
    subject.needs_admin_review = true

    subject.save!
    subject.reload

    subject.state.should == '{ some: "blob", of: "json" }'
    subject.node.should == "10.11.12.13"
    subject.pid.should == 808
    subject.needs_admin_review.should == true
  end

  it 'pretty_state should not choke on nil' do
    setup_item(subject)
    subject.state = nil
    subject.pretty_state.should == nil
  end

  it 'pretty_state should not choke on empty string' do
    setup_item(subject)
    subject.state = ''
    subject.pretty_state.should == nil
  end

  it 'pretty_state should produce formatted JSON' do
    setup_item(subject)
    subject.state = '{ "here": "is", "some": ["j","s","o","n"] }'
    pretty_json = <<-eos
{
  "here": "is",
  "some": [
    "j",
    "s",
    "o",
    "n"
  ]
}
eos
    subject.pretty_state.should == pretty_json.strip
  end

  describe 'work queue methods' do
    ingest_date = Time.parse('2014-06-01')
    before do
      3.times do
        ingest_date = ingest_date + 1.days
        FactoryGirl.create(:processed_item, object_identifier: 'abc/123',
                           action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                           stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                           status: Fluctus::Application::FLUCTUS_STATUSES['success'],
                           date: ingest_date)
      end
    end

    it 'should return the last ingested version when asked' do
      pi = ProcessedItem.last_ingested_version('abc/123')
      pi.object_identifier.should == 'abc/123'
      pi.date.should == ingest_date
    end

    it 'should create a restoration request when asked' do
      pi = ProcessedItem.create_restore_request('abc/123', 'mikey@example.com')
      pi.action.should == Fluctus::Application::FLUCTUS_ACTIONS['restore']
      pi.stage.should == Fluctus::Application::FLUCTUS_STAGES['requested']
      pi.status.should == Fluctus::Application::FLUCTUS_STATUSES['pend']
      pi.note.should == 'Restore requested'
      pi.outcome.should == 'Not started'
      pi.user.should == 'mikey@example.com'
      pi.retry.should == true
      pi.reviewed.should == false
      pi.state.should be_nil
      pi.node.should be_nil
      pi.pid.should == 0
      pi.needs_admin_review.should == false
      pi.id.should_not be_nil
    end

    it 'should create a dpn request when asked' do
      pi = ProcessedItem.create_dpn_request('abc/123', 'mikey@example.com')
      pi.action.should == Fluctus::Application::FLUCTUS_ACTIONS['dpn']
      pi.stage.should == Fluctus::Application::FLUCTUS_STAGES['requested']
      pi.status.should == Fluctus::Application::FLUCTUS_STATUSES['pend']
      pi.note.should == 'Requested item be sent to DPN'
      pi.outcome.should == 'Not started'
      pi.user.should == 'mikey@example.com'
      pi.retry.should == true
      pi.reviewed.should == false
      pi.state.should be_nil
      pi.node.should be_nil
      pi.pid.should == 0
      pi.needs_admin_review.should == false
      pi.id.should_not be_nil
    end

    it 'should create a delete request when asked' do
      pi = ProcessedItem.create_delete_request('abc/123', 'abc/123/doc.pdf', 'mikey@example.com')
      pi.action.should == Fluctus::Application::FLUCTUS_ACTIONS['delete']
      pi.stage.should == Fluctus::Application::FLUCTUS_STAGES['requested']
      pi.status.should == Fluctus::Application::FLUCTUS_STATUSES['pend']
      pi.note.should == 'Delete requested'
      pi.outcome.should == 'Not started'
      pi.user.should == 'mikey@example.com'
      pi.retry.should == true
      pi.reviewed.should == false
      pi.generic_file_identifier.should == 'abc/123/doc.pdf'
      pi.state.should be_nil
      pi.node.should be_nil
      pi.pid.should == 0
      pi.needs_admin_review.should == false
      pi.id.should_not be_nil
    end

  end
end
