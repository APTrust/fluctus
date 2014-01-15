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
    Solrizer.insert_field(solr_doc, 'institution_id', institution.id, :symbol)
    Solrizer.insert_field(solr_doc, "#{namespaced_solr_field_base}_id", self.id, :symbol)

    if self.respond_to?(:uri)
      Solrizer.insert_field(solr_doc, "#{namespaced_solr_field_base}_uri", self.uri, :symbol)
    end

    if self.respond_to?(:intellectual_object_id)
      Solrizer.insert_field(solr_doc, "intellectual_object_id", self.intellectual_object_id, :symbol)
    end

    ActiveFedora::SolrService.add(solr_doc)
    ActiveFedora::SolrService.commit
  end

  # Example:  A GenericFile that has a premisEvent.
  # The solr doc for the event will have some fields that
  # describe the GenericFile, such as generic_file_id_ssim
  # and generic_file_uri_ssim.
  def namespaced_solr_field_base
    self.class.to_s.demodulize.underscore
  end

end
