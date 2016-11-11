desc 'Run specs'
RSpec::Core::RakeTask.new(:rspec => 'test:prepare') { |t| t.rspec_opts = ['--colour', '--profile 20'] }

namespace :fluctus do

  # DPN member UUIDs are at
  # https://docs.google.com/spreadsheets/d/1-WFK0me8dM2jETlUkI7wpmRFMOgHC5LhyYk6hgHOfIA/
  partner_list = [
        ['APTrust', 'apt', 'aptrust.org', nil],
        ['Columbia University', 'cul', 'columbia.edu', 'ed73acd4-93e9-4196-a1ba-7fc8031b5f0b'],
        ['Indiana University Bloomington', 'iub', 'indiana.edu', '77abdcc5-6d50-441b-8fd7-8085ceba5f05'],
        ['Johns Hopkins University', 'jhu', 'jhu.edu', '0ab32901-5377-4928-898c-f4c5e2cde8e1'],
        ['North Carolina State University', 'ncsu', 'ncsu.edu', 'd3432b4f-9f82-4206-a086-89bff5c5bd1e'],
        ['Pennsylvania State University', 'pst', 'psu.edu', 'cf153594-6c22-4b59-a12e-420e0ae5280f'],
        ['Syracuse University', 'syr', 'syr.edu', 'd5e231ad-cf1f-4499-9afe-7045f1254eaa'],
        ['Test University','test', 'test.edu', 'fe908327-3635-43c2-9ca6-849485febcf3'],
        ['University of Chicago', 'uchi', 'uchicago.edu', nil],
        ['University of Cincinnati', 'ucin', 'uc.edu', nil],
        ['University of Connecticut', 'uconn', 'uconn.edu', nil],
        ['University of Maryland', 'mdu', 'umd.edu', 'a905b4da-cb04-43b9-8e23-ee43e02b23df'],
        ['University of Miami', 'um', 'miami.edu', '41d34f47-ab83-4fa3-a40d-85465bc5fd14'],
        ['University of Michigan', 'umich', 'umich.edu', '7277cbab-d539-4a81-ac1e-70cefc28fb2e'],
        ['University of North Carolina at Chapel Hill', 'unc', 'unc.edu', 'cdd177a9-fe6b-4b75-9960-d808d1fb5570'],
        ['University of Notre Dame', 'und', 'nd.edu', 'e25e97d2-44fe-472b-bbfe-6efc71dae268'],
        ['University of Virginia','uva', 'virginia.edu', '63fd28df-4178-48e0-b259-343f82f04551'],
        ['Virginia Tech','vatech', 'vt.edu', '77b67409-2966-4ea9-95f8-fef59b12ee29']
  ]


  desc 'Setup Fluctus'
  task setup: :environment do
    admintest = User.where(name: 'APTrust Admin')

    if admintest.name != 'APTrust Admin'
      puts "Creating an initial institution named 'APTrust'..."
      i = Institution.create!(name: 'APTrust', identifier: 'aptrust.org', brief_name: 'apt', dpn_uuid: '44c450a6-8b2e-4c59-8793-3d9366bf43f5')

      puts "Creating required roles of 'admin', 'institutional_admin', and 'institutional_user'..."
      %w(admin institutional_admin institutional_user).each do |role|
        Role.create!(name: role)
      end

      puts 'Create an initial Super-User for APTrust...'
      name = 'APTrust Admin'
      email = 'ops@aptrust.org'
      phone_number = '4341234567'
      password = 'password'
      User.create!(name: name, email: email, password: password, phone_number: phone_number, institution_pid: i.pid,
                   role_ids: [Role.where(name: 'admin').first.id])
    else
      puts 'Setup seems to have run already. Admin user exists. Exiting.'
    end
  end

  # Restricted only to non-production environments
  desc 'Empty the database'
  task empty_db: :environment do
    unless Rails.env.production?
      [User, GenericFile, IntellectualObject, Institution, Role, ProcessedItem].each(&:destroy_all)
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
      partner = partner_list[count+1]
      i = FactoryGirl.create(:institution, name: partner[0], brief_name: partner[1],
                         identifier: partner[2], dpn_uuid: partner[3])
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
        FactoryGirl.create(:processed_item, institution: institution.identifier, name: bag_name, action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'], stage: Fluctus::Application::FLUCTUS_STAGES['record'], status: Fluctus::Application::FLUCTUS_STATUSES['success'])

        5.times.each do |count|
          FactoryGirl.create(:processed_item, institution: institution.identifier)
        end

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
      partner = partner_list[count]
      FactoryGirl.create(:institution,
                         name: partner[0],
                         brief_name: partner[1],
                         identifier: partner[2],
                         dpn_uuid: partner[3])
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

  desc 'Dumps objects, files, institutions and events to JSON files for auditing'
  task :dump_data, [:data_dir, :since_when] => [:environment] do |t, args|
    #
    # Sample usage to dump all objects and institutions into /usr/local/data:
    #
    # bundle exec rake fluctus:dump_data[/usr/local/data]
    #
    # To dump objects updated since a specified time to the same directory:
    #
    # bundle exec rake fluctus:dump_data[/usr/local/data,'2016-01-04T20:00:48.248Z']
    #
    data_dir = args[:data_dir] || '.'
    since_when = args[:since_when] || DateTime.new(1900,1,1).iso8601
    inst_file = File.join(data_dir, 'institutions.json')
    puts "Dumping institutions to #{inst_file}"
    File.open(inst_file, 'w') do |file|
      Institution.all.each do |inst|
        file.puts(inst.to_json)
      end
    end
    objects_file = File.join(data_dir, 'objects.json')
    timestamp_file = File.join(data_dir, 'timestamp.txt')
    last_timestamp = since_when
    proceed_to_reify = false
    number_skipped = 0
    puts "Dumping objects, files and events modified since #{since_when} to #{objects_file}"
    begin
      File.open(objects_file, 'w') do |file|
        IntellectualObject.find_in_batches([], batch_size: 10, sort: 'system_modified_dtsi asc') do |solr_result|
          # Don't process or even reify results we've already processed,
          # because the reify process blows up the memory and leads
          # to out-of-memory crashes. We have to keep track of the last
          # intellectual object we processed, because memory leaks somewhere
          # in the Rails/Hydra/ActiveFedora stack cause this process to crash
          # consistently, and we need to be able to restart where we left off.
          if proceed_to_reify == false
            solr_result.each do |result|
              record_modified = result['system_modified_dtsi']
              if record_modified > since_when
                proceed_to_reify = true
                break
              end
              number_skipped += 1
            end
          end
          next if proceed_to_reify == false
          obj_list = ActiveFedora::SolrService.reify_solr_results(solr_result)
          obj_list.each do |io|
            data = io.serializable_hash(include: [:premisEvents])
            data[:generic_files] = []
            io.generic_files.each do |gf|
              data[:generic_files].push(gf.serializable_hash(include: [:checksum, :premisEvents]))
            end
            file.puts(data.to_json)
            last_timestamp = io.modified_date
          end

          # Do our part to remediate memory leaks
          obj_list.each { |io| io = nil }
          obj_list = nil
          solr_result = nil
          data = nil
          GC.start
        end
      end
    ensure
      puts("Skipped #{number_skipped} records modified before #{since_when}.")
      puts("Finished dumping objects with last mod date through #{last_timestamp}")
      puts("Writing timestamp to #{timestamp_file}")
      puts('If this process crashed, you can resume the data dump where it left off.')
      puts("First, MOVE THE FILE #{objects_file} SO IT DOESN'T GET OVERWRITTEN.")
      puts('Then run the following command:')
      puts("bundle exec rake fluctus:dump_data[#{data_dir},'#{last_timestamp}']")
      File.open(timestamp_file, 'w') { |file| file.puts(last_timestamp) }
    end
  end

  desc 'Dumps ProcessedItem records to JSON files for auditing'
  task :dump_processed_items, [:data_dir, :since_when] => [:environment] do |t, args|
    data_dir = args[:data_dir] || '.'
    since_when = args[:since_when] || DateTime.new(1900,1,1).iso8601
    output_file = File.join(data_dir, 'processed_items.json')
    puts "Dumping processed_items to #{output_file}"
    File.open(output_file, 'w') do |file|
      ProcessedItem.where('updated_at >= ?', since_when).order('updated_at asc').find_each do |item|
        file.puts(item.to_json)
      end
    end
  end

  desc 'Dumps User records to JSON files for auditing'
  task :dump_users, [:data_dir] => [:environment] do |t, args|
    data_dir = args[:data_dir] || '.'
    output_file = File.join(data_dir, 'users.json')
    puts "Dumping users to #{output_file}"
    File.open(output_file, 'w') do |file|
      User.find_each do |user|
        data = user.serializable_hash
        data['encrypted_password'] = user.encrypted_password
        data['encrypted_api_secret_key'] = user.encrypted_api_secret_key
        file.puts(data.to_json)
      end
    end
  end

  desc 'Dump all repository data to SQLite for transfer to Pharos'
  task :dump_repository => :environment do
    start = Time.now
    puts "Starting time: #{start}"

    db = SQLite3::Database.new 'fedora_export.db'
    db.execute(
      'CREATE TABLE users (
         id INTEGER PRIMARY KEY,
         email TEXT,
         encrypted_password TEXT,
         reset_password_token TEXT,
         reset_password_sent_at TEXT,
         remember_created_at TEXT,
         sign_in_count INTEGER,
         current_sign_in_at TEXT,
         last_sign_in_at TEXT,
         current_sign_in_ip TEXT,
         last_sign_in_ip TEXT,
         created_at TEXT,
         updated_at TEXT,
         name TEXT,
         phone_number TEXT,
         institution_pid TEXT,
         encrypted_api_secret_key TEXT
      );')
    db.execute(
      'CREATE TABLE institutions (
         id TEXT PRIMARY KEY,
         name TEXT,
         brief_name TEXT,
         identifier TEXT,
         dpn_uuid TEXT
      );')
    db.execute(
      'CREATE TABLE intellectual_objects (
         id TEXT PRIMARY KEY,
         identifier TEXT,
         title TEXT,
         description TEXT,
         alt_identifier TEXT,
         access TEXT,
         bag_name TEXT,
         institution_id TEXT,
         state TEXT
      );')
    db.execute(
      'CREATE TABLE generic_files (
         id TEXT PRIMARY KEY,
         file_format TEXT,
         uri TEXT,
         size REAL,
         intellectual_object_id TEXT,
         identifier TEXT,
         created_at TEXT,
         updated_at TEXT
      );')
    db.execute(
      'CREATE TABLE premis_events (
         intellectual_object_id TEXT,
         generic_file_id TEXT,
         institution_id TEXT,
         intellectual_object_identifier TEXT,
         generic_file_identifier TEXT,
         identifier TEXT,
         event_type TEXT,
         date_time TEXT,
         detail TEXT,
         outcome TEXT,
         outcome_detail TEXT,
         outcome_information TEXT,
         object TEXT,
         agent TEXT
      );')
    db.execute(
      'CREATE TABLE checksums (
         algorithm TEXT,
         datetime TEXT,
         digest TEXT,
         generic_file_id TEXT
      );')
    db.execute(
      'CREATE TABLE processed_items (
         id INTEGER PRIMARY KEY,
         created_at TEXT,
         updated_at TEXT,
         name TEXT,
         etag TEXT,
         bucket TEXT,
         user TEXT,
         institution TEXT,
         note TEXT,
         action TEXT,
         stage TEXT,
         status TEXT,
         outcome TEXT,
         bag_date TEXT,
         date TEXT,
         retry TEXT,
         reviewed TEXT,
         object_identifier TEXT,
         generic_file_identifier TEXT,
         state TEXT,
         node TEXT,
         pid INTEGER,
         needs_admin_review TEXT
      );')

    BATCH_SIZE = 10
    event_count = 0
    ck_count = 0
    counter = 0

    puts 'Users'
    User.all.each do |user|
      db.execute('INSERT INTO users (id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at,
                  sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, created_at, updated_at,
                  name, phone_number, institution_pid, encrypted_api_secret_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  user.id, user.email, user.encrypted_password, user.reset_password_token.to_s, user.reset_password_sent_at.to_s, user.remember_created_at.to_s,
                  user.sign_in_count, user.current_sign_in_at.to_s, user.last_sign_in_at.to_s, user.current_sign_in_ip.to_s, user.last_sign_in_ip.to_s,
                  user.created_at.to_s, user.updated_at.to_s, user.name, user.phone_number, user.institution_pid, user.encrypted_api_secret_key)
    end

    puts 'Institutions'
    Institution.all.each do |inst|
      db.execute('INSERT INTO institutions (id, name, brief_name, identifier, dpn_uuid) VALUES (?, ?, ?, ?, ?)',
                  inst.id, inst.name, inst.brief_name, inst.identifier, inst.dpn_uuid)
      puts '.'

      puts "Intellectual Objects, in batches of #{BATCH_SIZE}, with associated files, events, and checksums"
      #IntellectualObject.find_in_batches([], batch_size: BATCH_SIZE) do |batch|
      inst.intellectual_objects.each do |object|
        #batch.each do |solr_hash|
          #object = IntellectualObject.get_from_solr(solr_hash['id'])
          #inst = object.institution
        db.execute('INSERT INTO intellectual_objects (id, identifier, title, description, alt_identifier, access, bag_name, institution_id,
                    state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', object.id, object.identifier, object.title,
                    object.description, object.alt_identifier, object.access, object.bag_name, inst.id, object.state)
        object.premisEvents.events.each do |event|
          if event.generic_file_id.nil?
            db.execute('INSERT INTO premis_events (intellectual_object_id, generic_file_id, institution_id, intellectual_object_identifier,
                      generic_file_identifier, identifier, event_type, date_time, detail, outcome, outcome_detail, outcome_information, object,
                      agent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', object.id, nil, inst.id, object.identifier, nil, event.identifier,
                       event.type, event.date_time.to_s, event.detail, event.outcome, event.outcome_detail, event.outcome_information,
                       event.object, event.agent)
            event_count = event_count + 1
          end
        end
        object.generic_files.each do |file|
          db.execute('INSERT INTO generic_files (id, file_format, uri, size, intellectual_object_id, identifier, created_at, updated_at)
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?)', file.id, file.file_format, file.uri, file.size, object.id, file.identifier,
                      file.created.to_s, file.modified.to_s)
          file.premisEvents.events.each do |event|
            db.execute('INSERT INTO premis_events (intellectual_object_id, generic_file_id, institution_id, intellectual_object_identifier,
                        generic_file_identifier, identifier, event_type, date_time, detail, outcome, outcome_detail, outcome_information, object,
                        agent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', object.id,
                        file.id, inst.id, object.identifier, file.identifier, event.identifier,
                        event.type, event.date_time.to_s, event.detail, event.outcome, event.outcome_detail, event.outcome_information,
                        event.object, event.agent)
            event_count = event_count + 1
          end
          file.checksum.each do |ck|
            db.execute('INSERT INTO checksums (algorithm, datetime, digest, generic_file_id) VALUES (?, ?, ?, ?)',
                        ck.algorithm.first, ck.datetime.first.to_s, ck.digest.first, file.id)
            ck_count = ck_count + 1
          end
        end
        puts counter
        counter = counter + 1
        #puts counter if counter % BATCH_SIZE == 0
      end
    end

    puts 'Processed Items'
    ProcessedItem.all.each do |pi|
      db.execute('INSERT INTO processed_items (id, created_at, updated_at, name, etag, bucket, user, institution, note, action, stage, status,
                  outcome, bag_date, date, retry, reviewed, object_identifier, generic_file_identifier, state, node, pid, needs_admin_review)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', pi.id, pi.created_at.to_s, pi.updated_at.to_s, pi.name,
                  pi.etag, pi.bucket, pi.user, pi.institution, pi.note, pi.action, pi.stage, pi.status, pi.outcome, pi.bag_date.to_s, pi.date.to_s, pi.retry.to_s,
                  pi.reviewed.to_s, pi.object_identifier, pi.generic_file_identifier, pi.state, pi.node, pi.pid, pi.needs_admin_review.to_s)
    end

    puts "Number of users in Fluctus: #{User.all.count}"
    db.execute 'SELECT COUNT(*) FROM users' do |row|
      puts "Number of user rows in new db: #{row[0]}"
    end

    puts "Number of institutions in Fluctus: #{Institution.all.count}"
    db.execute 'SELECT COUNT(*) FROM institutions' do |row|
      puts "Number of institution rows in new db: #{row[0]}"
    end

    puts "Number of processed items in Fluctus: #{ProcessedItem.all.count}"
    db.execute 'SELECT COUNT(*) FROM processed_items' do |row|
      puts "Number of processed item rows in new db: #{row[0]}"
    end

    puts "Number of intellectual objects in Fluctus: #{IntellectualObject.all.count}"
    db.execute 'SELECT COUNT(*) FROM intellectual_objects' do |row|
      puts "Number of object rows in new db: #{row[0]}"
    end

    puts "Number of generic files in Fluctus: #{GenericFile.all.count}"
    db.execute 'SELECT COUNT(*) FROM generic_files' do |row|
      puts "Number of file rows in new db: #{row[0]}"
    end

    puts "Number of premis events in Fluctus: #{event_count}"
    db.execute 'SELECT COUNT(*) FROM premis_events' do |row|
      puts "Number of event rows in new db: #{row[0]}"
    end

    puts "Number of checksums in Fluctus: #{ck_count}"
    db.execute 'SELECT COUNT(*) FROM checksums' do |row|
      puts "Number of checksum rows in new db: #{row[0]}"
    end

    # db.execute 'SELECT identifier, event_type FROM premis_events' do |row|
    #   puts "Double checking values: #{row[0]}"
    #   puts "Double checking values: #{row[1]}"
    # end

    end_time = Time.now
    puts "Ending time: #{end_time}"
  end

end
