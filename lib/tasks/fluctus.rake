desc 'Run specs'
RSpec::Core::RakeTask.new(:rspec => 'test:prepare') { |t| t.rspec_opts = ['--colour', '--profile 20'] }

namespace :fluctus do

  partner_list = [
        ['APTrust', 'apt', 'aptrust.org'],
        ['Columbia University', 'cul', 'columbia.edu'],
        ['Johns Hopkins University', 'jhu', 'jhu.edu'],
        ['North Carolina State University', 'ncsu', 'ncsu.edu'],
        ['Pennsylvania State University', 'psu', 'psu.edu'],
        ['Syracuse University', 'syr', 'syr.edu'],
        ['University of Chicago', 'uchi', 'uchicago.edu'],
        ['University of Cincinnati', 'ucin', 'uc.edu'],
        ['University of Connecticut', 'uconn', 'uconn.edu'],
        ['University of Maryland', 'mdu', 'umd.edu'],
        ['University of Miami', 'um', 'miami.edu'],
        ['University of Michigan', 'umich', 'umich.edu'],
        ['University of North Carolina at Chapel Hill', 'unc', 'unc.edu'],
        ['University of Notre Dame', 'und', 'nd.edu'],
        ['University of Virginia','uva', 'virginia.edu'],
        ['Virginia Tech','vatech', 'vt.edu'],
        ['Test University','test', 'test.edu'],
        ['Indiana University Bloomington', 'iub', 'indiana.edu']
  ]


  desc 'Setup Fluctus'
  task setup: :environment do
    desc "Creating an initial institution names 'APTrust'..."

    i = Institution.create!(name: 'APTrust', identifier: 'aptrust.org', brief_name: 'apt')

    desc "Creating required roles of 'admin', 'institutional_admin', and 'institutional_user'..."
    %w(admin institutional_admin institutional_user).each do |role|
      Role.create!(name: role)
    end

    desc 'Create an initial Super-User for APTrust...'
    STDOUT.puts 'What is your name?'
    name = STDIN.gets.strip

    STDOUT.puts 'What is your email?'
    email = STDIN.gets.strip

    STDOUT.puts 'What is your phone number?'
    phone_number = STDIN.gets.strip

    STDOUT.puts 'Create a password.'
    password = STDIN.gets.strip

    User.create!(name: name, email: email, password: password, phone_number: phone_number, institution_pid: i.pid,
                 role_ids: [Role.where(name: 'admin').first.id])
  end

  # Restricted only to non-production environments
  desc 'Empty the database'
  task empty_db: :environment do
    unless Rails.env.production?
      [User, GenericFile, IntellectualObject, Institution, Role, ProcessedItem, IoAggregation].each(&:destroy_all)
    end
  end

  desc 'Delete all solr documents'
  task clean_solr: :environment do
    unless Rails.env.production?
      solr = ActiveFedora::SolrService.instance.conn
      solr.delete_by_query('*:*', params: { commit: true })
    end
  end

  desc 'Run ci'
  task :travis do
    puts 'Updating Solr config'
    Rake::Task['jetty:config'].invoke

    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config
    puts 'Starting Jetty'
    error = Jettywrapper.wrap(jetty_params) do
        Rake::Task['rspec'].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc 'Empty DB and add dummy information'
  task :populate_db, [:numInstitutions, :numIntObjects, :numGenFiles] => [:environment] do |_, args|
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end
    Rake::Task['fluctus:empty_db'].invoke
    Rake::Task['fluctus:clean_solr'].invoke
    Rake::Task['fluctus:setup'].invoke

    start = Time.now
    puts "Starting time: #{start}"

    args.with_defaults(:numInstitutions => partner_list.count-1, :numIntObjects => 1, :numGenFiles => 1)

    num_insts = args[:numInstitutions].to_i
    if num_insts > partner_list.count-1
      num_insts = partner_list.count-1
      puts "We currently have only #{partner_list.count-1} institutions."
    end

    puts "Creating #{num_insts} Institutions"
    num_insts.times.each do |count|
      puts "== Creating number #{count+1} of #{num_insts}: #{partner_list[count+1].first} "
      FactoryGirl.create(:institution, name: partner_list[count+1].first, brief_name: partner_list[count+1][1],
                         identifier: partner_list[count+1].last)
    end

    puts 'Creating Users for each Institution'
    Institution.all.each do |institution|
      next unless institution.name != 'APTrust'

      puts "Populating content for #{institution.name}"

      num_users = rand(1..5)
      num_users.times.each do |count|
        puts "== Creating user #{count+1} of #{num_users} for #{institution.name}"
        FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid)
      end

      num_items = args[:numIntObjects].to_i
      num_items.times.each do |count|
        puts "== Creating intellectual object #{count+1} of #{num_items} for #{institution.name}"
        name = "#{SecureRandom.uuid}"
        bag_name = "#{name}.tar"
        ident = "#{institution.identifier}/#{name}"
        item = FactoryGirl.create(:intellectual_object, institution: institution, identifier: ident, bag_name: bag_name)
        item.add_event(FactoryGirl.attributes_for(:premis_event_ingest, detail: 'Metadata recieved from bag.', outcome_detail: '', outcome_information: 'Parsed as part of bag submission.'))
        item.add_event(FactoryGirl.attributes_for(:premis_event_identifier, outcome_detail: item.pid, outcome_information: 'Assigned by Fedora.'))

        # add processed item for intellectual object
        FactoryGirl.create(:processed_item, institution: institution.identifier, name: name, action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'], stage: Fluctus::Application::FLUCTUS_STAGES['record'], status: Fluctus::Application::FLUCTUS_STATUSES['success'])

        # add an aggregation object for the intellectual object
        aggregate = IoAggregation.new
        aggregate.initialize_object(item.id)
        aggregate.save!

        # for mark as reviewed testing, add a bunch of other fake processed items.
        # proc_items = 5
        # proc_items.times.each do
        #   FactoryGirl.create(:processed_item, institution: institution.identifier, action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'], stage: Fluctus::Application::FLUCTUS_STAGES['record'], status: Fluctus::Application::FLUCTUS_STATUSES['success'])
        # end

        num_files = args[:numGenFiles].to_i
        num_files.times.each do |file_count|
          puts "== ** Creating generic file object #{file_count+1} of #{num_files} for intellectual_object #{ item.pid }"
          f = FactoryGirl.build(:generic_file, intellectual_object: item)
          # crappy hack here but I'm running out of time. Create some techMetadata for them.
          format = [
              {ext: 'txt', type: 'plain/text'},
              {ext: 'xml', type: 'application/xml'},
              {ext: 'xml', type: 'application/rdf+xml'},
              {ext: 'pdf', type: 'application/pdf'},
              {ext: 'tif', type: 'image/tiff'},
              {ext: 'mp4', type: 'video/mp4'},
              {ext: 'wav', type: 'audio/wav'},
              {ext: 'pdf', type: 'application/pdf'}
          ].sample
          name = Faker::Lorem.characters(char_count=rand(5..15))
          attrs = {
              file_format: "#{format[:type]}",
              uri: "file:///#{item.identifier}/data/#{name}#{file_count}.#{format[:ext]}",
              identifier: "#{item.identifier}/data/#{name}#{file_count}.#{format[:ext]}",
          }
          f.techMetadata.attributes = FactoryGirl.attributes_for(:generic_file_tech_metadata, file_format: attrs[:file_format], uri: attrs[:uri], identifier: attrs[:identifier])

          f.save!

          f.add_event(FactoryGirl.attributes_for(:premis_event_validation))
          f.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
          f.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check))
          f.save!
          aggregate.update_aggregations('add', f)
        end
      end
    end
  end

  desc 'Deletes all solr documents and processed items, recreates institutions & preserves users'
  task :reset_data => [:environment] do
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end

    user_inst = {}
    User.all.each do |user|
      user_inst[user.id] = user.institution.identifier
    end

    puts 'Deleting processed items'
    ProcessedItem.delete_all

    puts 'Deleting all Solr documents'
    Rake::Task['fluctus:clean_solr'].invoke

    puts 'Creating Institutions'
    partner_list.count.times.each do |count|
      puts "== Creating number #{count+1} of #{partner_list.count}: #{partner_list[count].first} "
      FactoryGirl.create(:institution, name: partner_list[count].first,
                                brief_name: partner_list[count][1],
                                identifier: partner_list[count].last)
    end

    user_inst.each do |user_id, inst_identifier|
      user = User.find(user_id)
      inst = Institution.where(desc_metadata__identifier_ssim: inst_identifier).first
      puts "Associating user #{user.email} with institution #{inst.name}"
      user.institution_pid = inst.pid
      user.save
    end
  end


  desc 'Deletes test.edu data from Go integration tests'
  task :delete_go_data => [:environment] do
    if Rails.env.production?
      puts 'Do not run in production!'
      return
    end
    count = ProcessedItem.where(institution: 'test.edu').delete_all
    puts "Deleted #{count} ProcessedItems for test.edu"
    IntellectualObject.all.each do |io|
      if io.identifier.start_with?('test.edu/')
        puts "Deleting IntellectualObject #{io.identifier}"
        io.generic_files.destroy_all
        io.destroy
      end
    end
    finish = Time.now
    diff = finish - start
    puts "Execution time is #{diff} seconds"
  end

end
