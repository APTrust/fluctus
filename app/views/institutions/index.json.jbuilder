json.array!(@institutions) do |institution|
  json.extract! institution, :title
  json.url institution_url(institution, format: :json)
end
