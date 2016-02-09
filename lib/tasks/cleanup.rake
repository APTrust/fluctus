# Cleanup tasks from audit_001, Feb. 2016
#
# Some items ingested in Fall, 2015 were not recorded
# properly in Fluctus. These tasks fix those items.
namespace :cleanup do

  desc 'Adds PREMIS events for items copied from S3 to Glacier'
  task :add_glacier_files => [:environment] do
    # This notes which S3 files were copied to Glacier by the
    # cleanup_001.py script. Those files needed to be copied because
    # a communication error from Fluctus caused ingest services
    # to stop processing the bag before files were copied to Glacier.
    query = %q(
        select b.identifier as bag_identifier, f.identifier as file_identifier,
        f.key as uuid, f.action_completed_at
        from aws_files f
        inner join bags b on f.bag_id = b.id
        where f.action = 'add' and f.action_completed_at is not null
    )
    run_query(query) do |row|
      identifier = row['file_identifier']
      generic_file = GenericFile.where(tech_metadata__identifier_ssim: identifier).first
      if generic_file.nil?
        puts("#{identifier} not found")
        next
      end
      copied_at = row['action_completed_at']
      uuid = row['uuid']
      puts("Ingest event for #{identifier}")
      event = {
        identifier: SecureRandom.uuid,
        type: 'ingest',
        outcome: 'Success',
        outcome_detail: 'Ingested to replication storage and assigned replication URL identifier as part of audit001/cleanup',
        outcome_information: "https://s3.amazonaws.com/aptrust.preservation.oregon/#{uuid}",
        date_time: copied_at,
        detail: "https://s3.amazonaws.com/aptrust.preservation.oregon/#{uuid}",
        object: 'APTrust audit and cleanup scripts for audit_001',
        agent: 'https://github.com/APTrust/auditing/blob/1.0/cleanup_001.py'
      }
      generic_file.add_event(event)
      generic_file.save()
    end
  end

  desc 'Adds PREMIS events saying AWS duplicate files deleted'
  task :delete_duplicate_files => [:environment] do
    # This cleans up files that were stored more than once in S3.
    # This is the result of multiple ingest attempts. This does not
    # delete files from Glacier, because audit results show no duplicates
    # were ever stored in Glacier. The actual deletions were completed
    # and recored by the script cleanup_001.py in the auditing repo.
    query = %q(
        select b.identifier as bag_identifier, f.identifier as file_identifier,
        f.key as uuid, f.action_completed_at
        from aws_files f
        inner join bags b on f.bag_id = b.id
        where f.action = 'delete' and f.action_completed_at is not null
    )
    run_query(query) do |row|
      identifier = row['file_identifier']
      generic_file = GenericFile.where(tech_metadata__identifier_ssim: identifier).first
      if generic_file.nil?
        puts("#{identifier} not found")
        next
      end
      deleted_at = row['action_completed_at']
      uuid = row['uuid']
      puts("Delete event for #{identifier}")
      event = {
        identifier: SecureRandom.uuid,
        type: 'delete',
        outcome: 'Success',
        outcome_detail: 'Deleted duplicate S3 copy as part of audit001/cleanup',
        outcome_information: "Deleted https://s3.amazonaws.com/aptrust.preservation.storage/#{uuid}",
        date_time: deleted_at,
        detail: "APTrust admin deleted https://s3.amazonaws.com/aptrust.preservation.storage/#{uuid} as part of audit001/cleanup because this file was stored twice in S3 under two different uuids.",
        object: 'APTrust audit and cleanup scripts for audit_001',
        agent: 'https://github.com/APTrust/auditing/blob/1.0/cleanup_001.py'
      }
      generic_file.add_event(event)
      generic_file.save()
    end
  end

  desc 'Changes file URLs and adds PREMIS events for items ingested more than once'
  task :change_file_urls => [:environment] do
    # These bags were ingested more than once. In one ingest, we managed to save
    # both the S3 and Glacier copies, but the URL points to a file that exists
    # only in S3. This changes the URL to point to the UUID that was stored in
    # both S3 and Glacier. These changes are made by the rake task, not by
    # cleanup_001.py.
    query = %q(
        select b.identifier as bag_identifier, u.identifier as file_identifier,
        u.old_url, u.new_url
        from urls u
        inner join bags b on u.bag_id = b.id
    )
    run_query(query) do |row|
      puts(row['file_identifier'])
    end
  end

  desc 'Updated ProcessedItems that were fixed after the audit'
  task :update_processed_items => [:environment] do
    # Mark all of the relevant ProcessedItem records as fixed
    query = 'select id, name, identifier from bags'
    run_query(query) do |row|
      bag_name = row['name']
      pi = ProcessedItem.where(name: bag_name,
                               status: 'Failed',
                               stage: 'Record').first
      if pi.nil?
        puts("Item for #{bag_name} not found.")
      else
        pi.stage = 'Cleanup'
        pi.status = 'Success'
        pi.outcome = 'Success'
        pi.note = "Item ingest was completed by APTrust admin after audit " +
          "and cleanup process, Feb. 9, 2016."
        puts(pi.inspect)
        # pi.save
      end
    end
  end


  def run_query(query, &block)
    if File.exist?('audit001_summary.db')
      conn = SQLite3::Database.open('audit001_summary.db')
      conn.results_as_hash = true
      conn.execute(query) do |row|
        yield row
      end
      conn.close()
    else
      puts("SQLite database audit001_summary.db is missing.")
      puts("That file is built by code in the Python auditing repo ")
      puts("and must be copied into the current working directory.")
      Kernel.exit(1)
    end
  end

end
