require 'spec_helper'

describe "Routing" do
  it "should route to the index when GET /generic_files/123" do
    expect(get: '/files/aptrust-dev:1').to route_to(controller: 'generic_files', action: 'show', id: 'aptrust-dev:1')
    expect(generic_file_path('aptrust-dev:1')).to eq '/files/aptrust-dev:1'
  end
  it "should route to create when POST /institutions/apt.org/123/objects" do
    expect(post: '/objects/apt.org/123/files').to route_to(controller: 'generic_files', action: 'create', intellectual_object_identifier: 'apt.org/123')
  end
  it "should route to update when PATCH /objects/apt.org/123/files/test/data/filename.xml" do
    expect(patch: '/objects/apt.org/123/files/test/data/filename.xml/').to route_to(controller: 'generic_files', action: 'update', intellectual_object_identifier: 'apt.org/123', id: 'test/data/filename.xml', format: "json", trailing_slash: true)
  end
end

