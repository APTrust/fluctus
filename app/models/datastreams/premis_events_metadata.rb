 # NOTE example of use https://gist.github.com/no-reply/4151387
# NOTE vocab link http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl
# NOTE official examples of use found in http://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CCsQFjAA&url=http%3A%2F%2Fwww.oclc.org%2Fresearch%2Fprojects%2Fpmwg%2Fpremis-examples.pdf&ei=JzCOUuuOAufLsASTgIKACA&usg=AFQjCNF3rVZ8JTF2IQEdWHCWZFC9eivcVQ&bvm=bv.56988011,d.cWc&cad=rja

# Note serialize via obj.serialize
class EventVocabulary < RDF::Vocabulary("http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl#")
  property :identifier
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
    map.type(to: :eventType, in: EventVocabulary)
    map.date_time(to: :eventDateTime, in: EventVocabulary)
    map.detail(to: :eventDetail, in: EventVocabulary)
    map.outcome(to: :eventOutcome, in: EventVocabulary)
    map.outcome_detail(to: :eventOutcomeDetail, in: EventVocabulary)
    map.outcome_information(to: :eventOutcomeInformation, in: EventVocabulary)
    map.object(to: :linkingObject, in: EventVocabulary)
    map.agent(to: :linkingAgent, in: EventVocabulary)
  end
end