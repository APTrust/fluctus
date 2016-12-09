require 'sqlite3'
namespace :export do

  task :export_repo, [:db_file] => [:environment] do |t, args|
	db_file = args[:db_file] || print_usage
	db = SQLite3::Database.new(db_file)
	create_tables(db)
	export_users(db)
	export_institutions(db)
	export_processed_items(db)
	export_objects(db)
	print_counts(db)
  end

  def export_users(db)
	User.all.each do |user|
	  db.execute('INSERT INTO users (id, email, encrypted_password, ' +
				 'reset_password_token, reset_password_sent_at, ' +
				 'remember_created_at, sign_in_count, current_sign_in_at, ' +
				 'last_sign_in_at, current_sign_in_ip, last_sign_in_ip, ' +
				 'created_at, updated_at, name, phone_number, ' +
				 'institution_pid, encrypted_api_secret_key, roles) VALUES ' +
				 '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
				 user.id, user.email, user.encrypted_password,
				 user.reset_password_token.to_s, user.reset_password_sent_at.to_s,
				 user.remember_created_at.to_s, user.sign_in_count,
				 user.current_sign_in_at.to_s, user.last_sign_in_at.to_s,
				 user.current_sign_in_ip.to_s, user.last_sign_in_ip.to_s,
				 user.created_at.to_s, user.updated_at.to_s, user.name,
				 user.phone_number, user.institution_pid,
				 user.encrypted_api_secret_key, user.roles_for_transition)
	end
	puts "Exported #{User.count} users"
  end

  def export_institutions(db)
	Institution.all.each do |inst|
	  db.execute('INSERT INTO institutions (id, name, brief_name, ' +
				 'identifier, dpn_uuid) VALUES (?, ?, ?, ?, ?)',
				 inst.id, inst.name, inst.brief_name, inst.identifier,
				 inst.dpn_uuid)
	end
	puts "Exported #{Institution.count} institutions"
  end

  def export_processed_items(db)
	ProcessedItem.all.each do |pi|
	  db.execute('INSERT INTO processed_items (id, created_at, updated_at, ' +
				 'name, etag, bucket, user, institution, note, action, ' +
				 'stage, status, outcome, bag_date, date, retry, reviewed, ' +
				 'object_identifier, generic_file_identifier, state, node, ' +
				 'pid, needs_admin_review) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ' +
				 '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
				 pi.id, pi.created_at.to_s, pi.updated_at.to_s, pi.name,
				 pi.etag, pi.bucket, pi.user, pi.institution, pi.note,
				 pi.action, pi.stage, pi.status, pi.outcome, pi.bag_date.to_s,
				 pi.date.to_s, pi.retry.to_s, pi.reviewed.to_s,
				 pi.object_identifier, pi.generic_file_identifier, pi.state,
				 pi.node, pi.pid, pi.needs_admin_review.to_s)
	end
	puts "Exported #{ProcessedItem.count} processed items"
  end

  def export_objects(db)
	count = 0
	IntellectualObject.find_in_batches([], batch_size: 10, sort: 'system_modified_dtsi asc') do |solr_result|
	  obj_list = ActiveFedora::SolrService.reify_solr_results(solr_result)
	  obj_list.each do |obj|
		export_object(db, obj)
		count += 1
	  end
	  if count % 100 == 0
		puts "Exported #{count} objects"
	  end
	end
  end

  def export_object(db, obj)
	inst = obj.institution
	db.execute('INSERT INTO intellectual_objects (id, identifier, title, ' +
			   'description, access, bag_name, institution_id, state, ' +
			   'alt_identifier) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
			   obj.id, obj.identifier, obj.title,
			   obj.description, obj.access, obj.bag_name, inst.id,
			   obj.state, obj.alt_identifier)

	obj.premisEvents.events.each do |event|
	  db.execute('INSERT INTO premis_events (intellectual_object_id, ' +
				 'generic_file_id, institution_id, ' +
				 'intellectual_object_identifier, generic_file_identifier, ' +
				 'identifier, event_type, date_time, detail, outcome, ' +
				 'outcome_detail, outcome_information, object, ' +
				 'agent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
				 obj.id, nil, inst.id, obj.identifier, nil,
				 event.identifier, event.type, event.date_time.to_s,
				 event.detail, event.outcome, event.outcome_detail,
				 event.outcome_information, event.object, event.agent)
	end
	obj.generic_files.each do |gf|
	  export_file(db, obj, inst, gf)
	end
  end

  def export_file(db, obj, inst, gf)
	db.execute('INSERT INTO generic_files (id, file_format, uri, size, ' +
			   'intellectual_object_id, identifier, created_at, updated_at) ' +
			   'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
			   gf.id, gf.file_format, gf.uri, gf.size, obj.id, gf.identifier,
			   gf.created.to_s, gf.modified.to_s)

	gf.premisEvents.events.each do |event|
	  db.execute('INSERT INTO premis_events (intellectual_object_id, ' +
				 'generic_file_id, institution_id, ' +
				 'intellectual_object_identifier, generic_file_identifier, ' +
				 'identifier, event_type, date_time, detail, outcome, ' +
				 'outcome_detail, outcome_information, object, '+
				 'agent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
				 obj.id, gf.id, inst.id, obj.identifier, gf.identifier,
				 event.identifier, event.type, event.date_time.to_s, event.detail,
				 event.outcome, event.outcome_detail, event.outcome_information,
				 event.object, event.agent)
	end
	gf.checksum.each do |ck|
	  db.execute('INSERT INTO checksums (algorithm, datetime, digest, ' +
				 'generic_file_id) VALUES (?, ?, ?, ?)',
				 ck.algorithm.first, ck.datetime.first.to_s,
				 ck.digest.first, gf.id)
	end
  end

  def get_count(db, table)
	count = 0
	query = "select count(*) from #{table}"
	db.execute(query) do |row|
	  count = row[0]
	end
	return count
  end

  def print_counts(db)
	puts "---------------- RESULTS -------------------"
	puts "Fedora users: #{User.count}"
	puts "SQLite users: #{get_count(db, 'users')}"
	puts "Fedora institutions: #{Institution.count}"
	puts "SQLite institutions: #{get_count(db, 'institutions')}"
	puts "Fedora processed items: #{ProcessedItem.count}"
	puts "SQLite processed items: #{get_count(db, 'processed_items')}"
	puts "Fedora objects: #{IntellectualObject.count}"
	puts "SQLite objects: #{get_count(db, 'intellectual_objects')}"
	puts "Fedora files: #{GenericFile.count}"
	puts "SQLite files: #{get_count(db, 'generic_files')}"
	puts "SQLite checksums: #{get_count(db, 'checksums')}"
	puts "SQLite events: #{get_count(db, 'premis_events')}"
  end

  def create_tables(db)
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
		 encrypted_api_secret_key TEXT,
		 roles TEXT
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
  end

  def print_usage
	puts "rake export:export_repo[db_file]\n"
	puts "Exports the entire Fedora repo to a SQLite DB.\n"
	puts "Param db file is required. Rake will create a sqlite3 file at that path."
	exit(1)
  end

end
