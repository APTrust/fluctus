require 'spec_helper'

describe "Routing" do
  it "should route to the index when GET /objects" do
    expect(get: '/institutions/aptrust.org/objects').to route_to(controller: 'intellectual_objects', action: 'index', institution_identifier: 'aptrust.org')
    expect(institution_intellectual_objects_path('aptrust.org')).to eq '/institutions/aptrust.org/objects'
  end
  it "should route to the show page when GET /objects/apt:123" do
    expect(get: '/objects/aptrust.org/12345678').to route_to(controller: 'intellectual_objects', action: 'show', intellectual_object_identifier: 'aptrust.org/12345678')
    expect(intellectual_object_path('aptrust.org/12345678')).to eq '/objects/aptrust.org/12345678'
  end
  it "should route to create when POST /institutions/aptrust.org/objects" do
    expect(post: '/institutions/aptrust.org/objects').to route_to(controller: 'intellectual_objects', action: 'create', institution_identifier: 'aptrust.org')
  end
end
