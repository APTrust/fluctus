require 'uuidtools'

# NOTE example of use https://gist.github.com/no-reply/4151387
# NOTE vocab link http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl
# NOTE official examples of use found in http://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CCsQFjAA&url=http%3A%2F%2Fwww.oclc.org%2Fresearch%2Fprojects%2Fpmwg%2Fpremis-examples.pdf&ei=JzCOUuuOAufLsASTgIKACA&usg=AFQjCNF3rVZ8JTF2IQEdWHCWZFC9eivcVQ&bvm=bv.56988011,d.cWc&cad=rja

# Note serialize via obj.serialize
class EventVocabulary < RDF::Vocabulary("http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl#")

  property :eventIdentifier
  property :eventType
  property :eventOutcome
  property :eventOutcomeDetail
  property :eventOutcomeInformation
  property :eventDateTime
  property :eventDetail
  property :linkingObject
  property :linkingAgent

  property :Event
end

class PremisEventsMetadata < ActiveFedora::RdfxmlRDFDatastream
  property :events, predicate: EventVocabulary.Event, class_name: 'Event'

  def serializable_hash(options={})
    events.map do |event|
      event.serializable_hash
    end
  end
  accepts_nested_attributes_for :events
end

class Event < ActiveTriples::Resource
  include ActiveFedora::RDF::Persistence
  configure :type => EventVocabulary

  property :identifier, predicate: EventVocabulary.eventIdentifier
  property :event_type, predicate: EventVocabulary.eventType
  property :date_time, predicate: EventVocabulary.eventDateTime
  property :detail, predicate: EventVocabulary.eventDetail
  property :outcome, predicate: EventVocabulary.eventOutcome
  property :outcome_detail, predicate: EventVocabulary.eventOutcomeDetail
  property :outcome_information, predicate: EventVocabulary.eventOutcomeInformation
  property :object, predicate: EventVocabulary.linkingObject
  property :agent, predicate: EventVocabulary.linkingAgent

  #noinspection RubyArgCount
  def initialize(graph=RDF::Graph.new, subject=nil)
    super
    init_identifier
    init_time
  end

  def to_solr(solr_doc={}, opts={})
    Solrizer.insert_field(solr_doc, 'event_identifier', self.identifier, :symbol)
    Solrizer.insert_field(solr_doc, 'event_type', self.event_type, :symbol)
    Solrizer.insert_field(solr_doc, 'event_outcome', self.outcome, :symbol)
    Solrizer.insert_field(solr_doc, 'event_date_time', self.date_time, :sortable, :symbol)
    Solrizer.insert_field(solr_doc, 'event_outcome_detail', self.outcome_detail, :symbol)
    Solrizer.insert_field(solr_doc, 'event_detail', self.detail, :symbol)
    Solrizer.insert_field(solr_doc, 'event_outcome_information', self.outcome_information, :symbol)
    Solrizer.insert_field(solr_doc, 'event_object', self.object, :symbol)
    Solrizer.insert_field(solr_doc, 'event_agent', self.agent, :symbol)
    solr_doc.merge!(SOLR_DOCUMENT_ID => self.identifier.first)
    solr_doc
  end

  # Serialize JSON for the API
  def serializable_hash(options={})
    {
        identifier: identifier.first,
        event_type: event_type.first,
        date_time: Time.parse(date_time.first).iso8601,
        detail: detail.first,
        outcome: outcome.first,
        outcome_detail: outcome_detail.first,
        object: object.first,
        agent: agent.first,
        outcome_information: outcome_information.first,
    }
  end

private
  def init_time
    self.date_time = Time.now.utc.iso8601 if self.date_time.empty?
  end

  def init_identifier
    self.identifier = UUIDTools::UUID.timestamp_create.to_s if self.identifier.empty?
  end

end
