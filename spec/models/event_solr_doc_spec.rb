require 'spec_helper'

describe EventSolrDoc do

  it 'has view partials in the events directory' do
    subject.to_partial_path.should == 'events/event'
  end

end
