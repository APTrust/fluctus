# Read about factories at https://github.com/thoughtbot/factory_girl

# Event examples pulled from http://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CCsQFjAA&url=http%3A%2F%2Fwww.oclc.org%2Fresearch%2Fprojects%2Fpmwg%2Fpremis-examples.pdf&ei=JzCOUuuOAufLsASTgIKACA&usg=AFQjCNF3rVZ8JTF2IQEdWHCWZFC9eivcVQ&bvm=bv.56988011,d.cWc&cad=rja

FactoryGirl.define do

  factory :premis_event_ingest do
    type { 'ingest' }
    date_time { "#{Time.now}" }
    detail { "copy to s3 preservation bucket aptrust_preservation" }
    outcome { "success" }
    outcome_detail { "Copied with MD5 put confirmation." }
    outcome_information { "Put using hash #{SecureRandom.hex(16)}" }
    object { "https://github.com/APTrust/fluctus" }
    # agent { "ruby s3 copy library" }
  end

  factory :premis_event_validation do
    type { 'validation' }
    date_time { "#{Time.now}" }
    detail { "Check against bag manifest checksum" }
    outcome { "success" }
    object { "https://github.com/APTrust/bagins" }
    # agent { "ruby s3 copy library" }
  end

  factory :premis_event_fixity_generation do
    type { 'fixity_generation' }
    date_time { "#{Time.now}" }
    detail { "Generation on file prior to copy to S3" }
    outcome { "sha256:#{SecureRandom.hex(32)}" }
    object { "https://github.com/APTrust/bagins" }
  end

  factory :premis_event_fixity_check do
    type { 'fixity_check' }
    date_time { "#{Time.now}" }
    #detail { "copy to s3 preservation bucket aptrust_preservation" }
    outcome { "success" }
    # outcome_detail { "Copied with MD5 put confirmation." }
    # outcome_information { "Put using hash #{SecureRandom.hex(16)}" }
    object { "https://github.com/APTrust/fluctus" }
    # agent { "ruby s3 copy library" }
  end

end
