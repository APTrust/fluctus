module Auditable
  extend ActiveSupport::Concern

  included do
    has_metadata "premisEvents", type: PremisEventsMetadata
  end

  def add_event(attributes)
    event = self.premisEvents.events.build(attributes)
    write_event_to_solr(event)
    event
  end

  def write_event_to_solr(event)
    solr_doc = event.to_solr
    Solrizer.insert_field(solr_doc, parent_key_for_events, self.id, :symbol)
    ActiveFedora::SolrService.add(solr_doc)
    ActiveFedora::SolrService.commit
  end

  def parent_key_for_events
    "#{self.class.to_s.demodulize.underscore}_id"
  end

end
