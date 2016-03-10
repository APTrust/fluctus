# Change Log

## 2016-03-10

* Added state, node, pid, and needs_admin_review to ProcessedItem. (REQUIRES MIGRATION)
* ProcessedItem.state stores JSON data describing the current state of a bag in process.
* Removed processed_item#get_reviewed, because Go services no longer need that endpoint.

## 2016-02-11

* Updating an IntellectualObject through our private internal API used to return :no_content, with status code 204. It now returns a JSON serialized version of the object, because the version of Phusion Passenger we're using has a bug that causes HTTP 204 responses to be invalid. The bug is described at https://github.com/phusion/passenger/issues/1595, and the symptom is a number of ingested bags that appear to have failed but were actually ingested.

## 2016-02-02

* Added member API with endpoints /member-api/v1/objects/ to list Intellectual Objects and /member-api/v1/items/ to list Processed Items. The member API is currently read-only.
* Removed all IOAggregations that caused performance problems. Aggregate counts and sums now come from Solr's built-in aggregate features.
