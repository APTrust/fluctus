require 'spec_helper'

describe "Routing" do
  it "should route to the index when GET /generic_files/123" do
    expect(get: '/files/aptrust-dev:1').to route_to(controller: 'generic_files', action: 'show', id: 'aptrust-dev:1')
    expect(generic_file_path('aptrust-dev:1')).to eq '/files/aptrust-dev:1'
  end
  it "should route to create when POST /institutions/aptrust-dev:1/objects" do
    expect(post: '/objects/aptrust-dev:1/files').to route_to(controller: 'generic_files', action: 'create', intellectual_object_id: 'aptrust-dev:1')
  end
  it "should route to update when PATCH /objects/aptrust-dev:1/files/test/data/filename.xml" do
    expect(patch: '/objects/aptrust-dev:1/files/test/data/filename.xml/').to route_to(controller: 'generic_files', action: 'update', intellectual_object_id: 'aptrust-dev:1', id: 'test/data/filename.xml', format: "json", trailing_slash: true)
  end
end

