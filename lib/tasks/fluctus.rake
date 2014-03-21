desc "Run specs"
RSpec::Core::RakeTask.new(:rspec => 'test:prepare') do |t|
  t.rspec_opts = ["--colour", '--profile 20']
end

namespace :fluctus do
  desc "Setup Fluctus"
  task setup: :environment do
    desc "Creating an initial institution names 'APTrust'..."
    i = FactoryGirl.create(:institution, name: "APTrust", brief_name: "apt", institution_identifier: "aptrust.org")

    desc "Creating required roles of 'admin', 'institutional_admin', and 'institutional_user'..."
    ['admin', 'institutional_admin', 'institutional_user'].each do |role|
      Role.create!(name: role)
    end

    desc "Create an initial Super-User for APTrust..."
    STDOUT.puts "What is your name?"
    name = STDIN.gets.strip

    STDOUT.puts "What is your email?"
    email = STDIN.gets.strip

    STDOUT.puts "What is your phone number?"
    phone_number = STDIN.gets.strip

    STDOUT.puts "Create a password."
    password = STDIN.gets.strip
   
    User.create!(name: name, email: email, password: password, phone_number: phone_number, institution_pid: i.pid,
                 role_ids: [Role.where(name: 'admin').first.id])
  end

  # Restricted only to non-production environments
  desc "Empty the database"
  task empty_db: :environment do
    if !Rails.env.production?
      [User, GenericFile, IntellectualObject, Institution, Role].each(&:destroy_all)
    end
  end

  desc "Delete all solr documents"
  task clean_solr: :environment do
    if !Rails.env.production?
      solr = ActiveFedora::SolrService.instance.conn
      solr.delete_by_query("*:*", params: { commit: true })
    end
  end

  desc "Run ci"
  task :travis do 
    puts "Updating Solr config"
    Rake::Task['jetty:config'].invoke
    
    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config
    puts "Starting Jetty"
    error = Jettywrapper.wrap(jetty_params) do
        Rake::Task['rspec'].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc "Empty DB and add dummy information"
  task :populate_db, [:numInstitutions, :numIntObjects, :numGenFiles] => [:environment] do |t, args|
    if Rails.env.production?
      puts "Do not run in production!"
      return
    end
    Rake::Task['fluctus:empty_db'].invoke
    Rake::Task['fluctus:clean_solr'].invoke
    Rake::Task['fluctus:setup'].invoke

    partner_list = [
        ["Columbia University", "cul", "columbia.edu"], ["North Carolina State University", "ncsu", "ncsu.edu"],
        ["Johns Hopkins University", "jhu", "jhu.edu"], ["University of Maryland", "mdu", "umd.edu"],
        ["University of Michigan", "umich", "umich.edu"], ["University of North Carolina at Chapel Hill", "unc", "unc.edu"],
        ["Syracuse University", "syr", "syr.edu"], ["University of Virginia","uva", "virginia.edu"],
        ["University of Notre Dame", "und", "nd.edu"], ["Stanford University", "stnfd", "stanford.edu"],
        ["University of Chicago", "uchi", "uchicago.edu"], ["University of Miami", "um", "miami.edu"],
        ["University of Connecticut", "uconn", "uconn.edu"], ["University of Cinnicnati", "ucin", "uc.edu"],
    ]

    args.with_defaults(:numInstitutions => partner_list.count, :numIntObjects => rand(5..10), :numGenFiles => rand(3..30))

    numInsts = args[:numInstitutions].to_i
    if (numInsts > partner_list.count)
      numInsts = partner_list.count
      puts "We currently have only #{partner_list.count} institutions."
    end

    puts "Creating #{numInsts} Institutions"
    numInsts.times.each do |count|
      puts "== Creating number #{count+1} of #{numInsts}: #{partner_list[count].first} "
      FactoryGirl.create(:institution, name: partner_list[count].first, brief_name: partner_list[count][1],
                         institution_identifier: partner_list[count].last)
    end

    puts "Creating Users for each Institution"
    Institution.all.each do |institution|
      next unless institution.name != "APTrust"

      puts "Populating content for #{institution.name}"

      numUsers = rand(1..5)
      numUsers.times.each do |count|
        puts "== Creating user #{count+1} of #{numUsers} for #{institution.name}"
        FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid)
      end

      numItems = args[:numIntObjects].to_i
      numItems.times.each do |count|
        puts "== Creating intellectual object #{count+1} of #{numItems} for #{institution.name}"
        ident = "#{institution.institution_identifier}/#{SecureRandom.hex(8)}"
        item = FactoryGirl.create(:intellectual_object, institution: institution, intellectualobject_identifier: ident)
        item.add_event(FactoryGirl.attributes_for(:premis_event_ingest, detail: "Metadata recieved from bag.", outcome_detail: "", outcome_information: "Parsed as part of bag submission."))
        item.add_event(FactoryGirl.attributes_for(:premis_event_identifier, outcome_detail: item.pid, outcome_information: "Assigned by Fedora."))

        numFiles = args[:numGenFiles].to_i
        numFiles.times.each do |count|
          puts "== ** Creating generic file object #{count+1} of #{numFiles} for intellectual_object #{ item.pid }"
          f = FactoryGirl.build(:generic_file, intellectual_object: item)
          # crappy hack here but I'm running out of time. Create some techMetadata for them.
          format = [
              {ext: "txt", type: "plain/text"},
              {ext: "xml", type: "application/xml"},
              {ext: "xml", type: "application/rdf+xml"},
              {ext: "pdf", type: "application/pdf"},
              {ext: "tif", type: "image/tiff"},
              {ext: "mp4", type: "video/mp4"},
              {ext: "wav", type: "audio/wav"},
              {ext: "pdf", type: "application/pdf"}
          ].sample

          attrs = {
              format: "#{format[:type]}",
              uri: "file:///#{item.intellectualobject_identifier.first}/data/#{Faker::Lorem.characters(char_count=rand(5..15))}#{count}.#{format[:ext]}",
          }
          f.techMetadata.attributes = FactoryGirl.attributes_for(:generic_file_tech_metadata, format: attrs[:format], uri: attrs[:uri])

          f.save!

          f.add_event(FactoryGirl.attributes_for(:premis_event_validation))
          f.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check))
          f.save!
        end
      end

    end
  end
end
