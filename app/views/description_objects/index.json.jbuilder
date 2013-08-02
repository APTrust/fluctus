json.array!(@description_objects) do |description_object|
  json.extract! description_object, 
  json.url description_object_url(description_object, format: :json)
end
