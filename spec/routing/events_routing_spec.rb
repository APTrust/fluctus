require 'spec_helper'

describe 'Routes for Events' do

  it 'has a route to create events for a generic file' do
    expect(
      post: 'files/apt.org/123/data/file.pdf/events'
    ).to(
      route_to(controller: 'events',
               action: 'create',
               generic_file_identifier: 'apt.org/123/data/file.pdf'
      )
    )
  end

  it 'has a route to create events for an intellectual object' do
    expect(
      post: 'objects/apt.org/123/events'
    ).to(
      route_to(controller: 'events',
               action: 'create',
               intellectual_object_identifier: 'apt.org/123'
      )
    )
  end

  it "has an index for an institution's events" do
    expect(
      get: 'institutions/testinst.com/events'
    ).to(
      route_to(controller: 'events',
               action: 'index',
               institution_identifier: 'testinst.com'
      )
    )
  end

  it "has an index for an intellectual object's events" do
    expect(
      get: 'objects/apt.org/123/events'
    ).to(
      route_to(controller: 'events',
               action: 'index',
               intellectual_object_identifier: 'apt.org/123'
      )
    )
  end

end
