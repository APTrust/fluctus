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
      puts(row['file_identifier'])
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
      puts(row['file_identifier'])
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
