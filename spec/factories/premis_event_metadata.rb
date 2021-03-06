# Read about factories at https://github.com/thoughtbot/factory_girl

# Event examples pulled from http://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CCsQFjAA&url=http%3A%2F%2Fwww.oclc.org%2Fresearch%2Fprojects%2Fpmwg%2Fpremis-examples.pdf&ei=JzCOUuuOAufLsASTgIKACA&usg=AFQjCNF3rVZ8JTF2IQEdWHCWZFC9eivcVQ&bvm=bv.56988011,d.cWc&cad=rja

FactoryGirl.define do

  factory :premis_event_ingest, class: PremisEventsMetadata do
    type { 'ingest' }
    date_time { "#{Time.now}" }
    detail { 'Completed copy to S3 storage' }
    outcome { 'success' }
    outcome_detail { "MD5:#{SecureRandom.hex(16)}" }
    outcome_information { 'Multipart Put using md5 checksum' }
    object { 'Goamz S3 Client' }
    agent { 'https://github.com/crowdmob/goamz' }

    factory :premis_event_ingest_fail do
      detail { 'Error copying to S3' }
      outcome { 'failure' }
    end

  end

  factory :premis_event_validation, class: PremisEventsMetadata do
    type { 'validation' }
    date_time { "#{Time.now}" }
    detail { 'Check against bag manifest checksum' }
    outcome { 'success' }
    object { 'https://github.com/APTrust/bagins' }
    # agent { "ruby s3 copy library" }
  end

  factory :premis_event_fixity_generation, class: PremisEventsMetadata do
    type { 'fixity_generation' }
    date_time { "#{Time.now}" }
    detail { 'Calculated new fixity value' }
    outcome { 'success' }
    outcome_detail { "sha256:#{SecureRandom.hex(64)}" }
    object { 'Go language cryptohash' }
    agent {'http://golang.org'}

    factory :premis_event_fixity_generation_fail do
      outcome { 'failure' }
      detail { 'Error reading file' }
      outcome_information { "error: unable to find file 'testfile.xml'" }
    end
  end

  factory :premis_event_fixity_check, class: PremisEventsMetadata do
    type { 'fixity_check' }
    date_time { "#{Time.now}" }
    detail { 'Fixity check against registered hash' }
    outcome { 'success' }
    outcome_detail { "SHA256:#{SecureRandom.hex(64)}" }
    outcome_information { 'Fixity matches' }
    object { 'Go language cryptohash' }
    agent { 'http://golang.org/' }

    factory :premis_event_fixity_check_fail do
      outcome { 'failure' }
      detail { 'Error, fixity does not match expected value' }
      outcome_information { "Acutal calculated hash was SHA256:#{SecureRandom.hex(64)}" }
    end
  end

  factory :premis_event_identifier, class: PremisEventsMetadata do
    type { 'identifier_assignment' }
    date_time { "#{Time.now}" }
    detail { 'S3 key generated for file' }
    outcome { 'success' }
    outcome_detail { "#{SecureRandom.uuid()}" }
    outcome_information { 'Generated with ruby SecureRandom.uuid()' }
    object { 'Ruby 2.0.1' }
    agent { 'http://www.ruby-doc.org/' }

    factory :premis_event_identifier_fail do
      outcome { 'failure' }
      detail {'Error generating S3 key'}
      outcome_detail { "" }
      outcome_information { 'File not found' }
    end
  end

end
