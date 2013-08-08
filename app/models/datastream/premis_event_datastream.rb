# NOTE example of use https://gist.github.com/no-reply/4151387
# NOTE vocab link http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl

class EventVocabulary < RDF::Vocabulary("http://multimedialab.elis.ugent.be/users/samcoppe/ontologies/Premis/premis.owl#")
  property :identifier
  property :eventType
  property :eventOutcomeDetail
  property :eventOutcomeInformation
  property :eventDateTime
  property :eventDetail
  property :linkingObject
  property :linkingAgent

  property :Event
end

class Datastream::PremisEventDatastream < ActiveFedora::RdfxmlRDFDatastream
  map_predicates do |map|
    map.events(to: :Event, in: EventVocabulary, class_name: "Event")
  end
end

class Event
  include ActiveFedora::RdfObject

  rdf_type EventVocabulary

  map_predicates do |map|
    map.identifier(to: :identifier, in: EventVocabulary)
    map.type(to: :eventType, in: EventVocabulary)
    map.date_time(to: :eventDateTime, in: EventVocabulary)
    map.detail(to: :eventDetail, in: EventVocabulary)
    map.outcome_detail(to: :eventDetail, in: EventVocabulary)
    map.outcome_information(to: :eventOutcomeInformation, in: EventVocabulary)
    map.object(to: :linkingObject, in: EventVocabulary)
    map.agent(to: :linkingAgent, in: EventVocabulary)
  end
end