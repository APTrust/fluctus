require 'rest_client'
require 'json'

# A very simple example script to update an existing 
# Intellectual Object with an API request

# ----------------------

email = 'frodo@example.com'
key = '123'
pid = 'aptrust-dev:238'
new_title = 'Title 6'
base_uri = 'http://localhost:3000'   # For production, require https

# ----------------------

puts "Updating Intellectual Object: pid: #{pid}, new title: #{new_title}"

objects_uri = base_uri + '/objects/' + pid
headers = { content_type: :json, accept: :json }

login_params = { user: { email: email, api_secret_key: key }}

data_to_update = { intellectual_object: { title: new_title }}
data_to_update.merge!(login_params)

response = RestClient.patch objects_uri, data_to_update.to_json, headers

# TODO:  Error handling

puts "Response: #{response.code}"
puts "Done"

