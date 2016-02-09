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
    # All of these files have a corrected URL.
    query = %q(
        select b.identifier as bag_identifier, f.identifier as file_identifier,
        f.key as uuid, f.action_completed_at, u.old_url, u.new_url
        from aws_files f
        inner join bags b on f.bag_id = b.id
        inner join urls u on f.identifier = u.identifier
        where f.action = 'delete' and f.action_completed_at is not null
    )
    run_query(query) do |row|
      identifier = row['file_identifier']
      generic_file = GenericFile.where(tech_metadata__identifier_ssim: identifier).first
      if generic_file.nil?
        puts("--> #{identifier} not found")
        next
      end
      new_url = row['new_url']
      if new_url.nil?
        puts("--> No new URL for #{identifier}")
        next
      end
      deleted_at = row['action_completed_at']
      uuid = row['uuid']
      puts("Adding delete event and correcting URL for #{identifier}")
      event = {
        identifier: SecureRandom.uuid,
        type: 'delete',
        outcome: 'Success',
        outcome_detail: 'Deleted duplicate S3 copy as part of audit001/cleanup',
        outcome_information: "Deleted https://s3.amazonaws.com/aptrust.preservation.storage/#{uuid}. Correct file url set to #{new_url}",
        date_time: deleted_at,
        detail: "APTrust admin deleted https://s3.amazonaws.com/aptrust.preservation.storage/#{uuid} as part of audit001/cleanup because this file was stored twice in S3 under two different uuids. Correct file uri set to #{new_url}",
        object: 'APTrust audit and cleanup scripts for audit_001',
        agent: 'https://github.com/APTrust/auditing/blob/1.0/cleanup_001.py'
      }
      #puts(event)
      generic_file.add_event(event)
      generic_file.uri = new_url
      generic_file.save()
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
          "and cleanup process, Feb. 9, 2016. As part of the audit/cleanup process, " +
          "any duplicate S3 files were deleted, and files missing from Glacier were " +
          "added, and these add/delete operations were recorded as PREMIS events."
        pi.object_identifier = row['identifier']
        puts(pi.inspect)
        pi.save
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
