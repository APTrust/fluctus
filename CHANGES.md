# Change Log

## 2016-02-02

* Added member API with endpoints /member-api/v1/objects/ to list Intellectual Objects and /member-api/v1/items/ to list Processed Items. The member API is currently read-only.
* Removed all IOAggregations that caused performance problems. Aggregate counts and sums now come from Solr's built-in aggregate features.
