require 'spec_helper'

describe "Routes for Events" do

  it 'has a route to create events for a generic file' do
    expect(
      post: 'files/hello:123/events'
    ).to(
      route_to(controller: 'events',
               action: 'create',
               generic_file_id: 'hello:123'
      )
    )
  end

  it 'has a route to create events for an intellectual object' do
    expect(
      post: 'objects/hello:123/events'
    ).to(
      route_to(controller: 'events',
               action: 'create',
               intellectual_object_id: 'hello:123'
      )
    )
  end

  it "has an index for an institution's events" do
    expect(
      get: 'institutions/testinst/events'
    ).to(
      route_to(controller: 'events',
               action: 'index',
               institution_identifier: 'testinst'
      )
    )
  end

  it "has an index for an intellectual object's events" do
    expect(
      get: 'objects/obj:123/events'
    ).to(
      route_to(controller: 'events',
               action: 'index',
               intellectual_object_id: 'obj:123'
      )
    )
  end

end
