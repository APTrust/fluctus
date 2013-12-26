require 'spec_helper'

describe "Routing" do
  it "should route to the index when GET /objects" do
    expect(get: '/institutions/aptrust-dev:1/objects').to route_to(controller: 'intellectual_objects', action: 'index', institution_id: 'aptrust-dev:1')
    expect(institution_intellectual_objects_path('aptrust-dev:1')).to eq '/institutions/aptrust-dev:1/objects'
  end
  it "should route to the show page when GET /objects/apt:123" do
    expect(get: '/objects/apt:123').to route_to(controller: 'intellectual_objects', action: 'show', id: 'apt:123')
    expect(intellectual_object_path('apt:123')).to eq '/objects/apt:123'
  end
end
