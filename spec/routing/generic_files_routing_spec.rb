require 'spec_helper'

describe "Routing" do
  it "should route to the index when GET /generic_files/123" do
    expect(get: '/files/aptrust-dev:1').to route_to(controller: 'generic_files', action: 'show', id: 'aptrust-dev:1')
    expect(generic_file_path('aptrust-dev:1')).to eq '/files/aptrust-dev:1'
  end
  it "should route to create when POST /institutions/aptrust-dev:1/objects" do
    expect(post: '/objects/aptrust-dev:1/files').to route_to(controller: 'generic_files', action: 'create', intellectual_object_id: 'aptrust-dev:1')
  end
end

