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
  map_predicates do |map|
    map.events(to: :Event, in: EventVocabulary, class_name: "Event")
  end

  accepts_nested_attributes_for :events
end

class Event
  include ActiveFedora::RdfObject

  rdf_type EventVocabulary

  map_predicates do |map|
    map.identifier(to: :eventIdentifier, in: EventVocabulary)
    map.type(to: :eventType, in: EventVocabulary)
    map.date_time(to: :eventDateTime, in: EventVocabulary)
    map.detail(to: :eventDetail, in: EventVocabulary)
    map.outcome(to: :eventOutcome, in: EventVocabulary)
    map.outcome_detail(to: :eventOutcomeDetail, in: EventVocabulary)
    map.outcome_information(to: :eventOutcomeInformation, in: EventVocabulary)
    map.object(to: :linkingObject, in: EventVocabulary)
    map.agent(to: :linkingAgent, in: EventVocabulary)
  end

  def initialize(graph=RDF::Graph.new, subject=nil)
    super
    init_identifier
    init_time
  end

  def to_solr(solr_doc={}, opts={})
    Solrizer.insert_field(solr_doc, 'event_type', self.type, :symbol)
    Solrizer.insert_field(solr_doc, 'event_outcome', self.outcome, :symbol)
    Solrizer.insert_field(solr_doc, 'event_date_time', self.date_time, :sortable, :symbol)
    solr_doc.merge!(SOLR_DOCUMENT_ID => self.identifier.first)
    solr_doc
  end

  # Serialize JSON for the API
  def serializable_hash(options={})
    {
        identifier: identifier.first,
        type: type.first,
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
    if self.identifier.empty?
      uuid = UUIDTools::UUID.timestamp_create
      self.identifier = uuid
    end
  end

end
