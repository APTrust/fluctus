require 'spec_helper'

describe 'generic_files/_premis_events.html.erb' do
#  let(:file) { FactoryGirl.create(:generic_file) }
#  let(:events) { Kaminari.paginate_array(file.premisEvents.events).page(1).per(2) }
#
#  after :all do
#    GenericFile.delete_all
#  end
#
#  describe 'a file without premis events' do
#    before do
#      assign(:events, events)
#      render partial: 'premis_events.html.erb'
#    end
#
#    it 'doesnt display the events table' do
#      file.premisEvents.events.count.should == 0
#      rendered.should have_text('There are no audit events')
#    end
#  end

  #describe 'a file with premis events' do
  #  before do
  #    p_events = []
  #    4.times {
  #      p_events << FactoryGirl.attributes_for(:premis_event_ingest)
  #    }
  #    file.premisEvents.events_attributes = p_events
  #    file.save!
  #
  #    controller.stub(:params).and_return(action: 'show', id: file.pid)
  #    assign(:events, events)
  #
  #    render partial: 'premis_events.html.erb'
  #  end
  #
  #  it 'paginates the events' do
  #    file.premisEvents.events.count.should == 4
  #    events.count.should == 2
  #    rendered.should have_link("Next »", href: generic_file_path(file, page: 2))
  #  end
  #end

end
