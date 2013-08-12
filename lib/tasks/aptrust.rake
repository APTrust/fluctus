namespace :aptrust do

  desc "Builds fedora bag models from all the bags in the configured S3 bucket."
  task load_bags: :environment do
    AWS::S3::Base.establish_connection!(
      access_key_id: ENV['S3_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_SECRET_ACCESS_KEY']
    )

    # Get the bags and prep a hash of their metadata we want
    # to register in Fedora
    bag_bucket = AWS::S3::Bucket.find(ENV['S3_BUCKET'])
    bag_data = Hash.new{|h,k| h[k] = []}
    bag_bucket.objects.each do |s3object|
      bag_id = s3object.path.split('/')[2]
      puts bag_id
      bag_data[bag_id] << s3object
    end
    puts "Found #{bag_data.count} bags...."

    # Iterate over bag data, create bags and add the fileManifest
    # metadata.
    bag_data.each do |key, files|
      puts "... processing bag #{key} ..."
      puts "... with #{files.count} files ..."
      bag = Bag.new
      mf = bag.fileManifest
      mf.title = key
      mf.uri = "#{ENV['S3_BUCKET']}/#{key}/"
      files.each do |f|
        mf.files.build(
            format: f.about['content-type'],
            uri: f.path,
            size: f.about['content-length'],
            created: f.about['last-modified'],
            modified: f.about['last-modified'],
            checksum_attributes: {
                algorithm: "md5",
                datetime: f.about['last-modified'],
                digest: f.about['etag']
            }
        )
      end
      puts "... saving bag #{key}"
      bag.save!
    end
    puts "Finished!"
  end

  # TODO DELETE THIS BEFORE GOING TO ANYTHING RESEMBLING PRODUCTION!
  desc "Removes all bags from Fedora."
  task purge_bags: :environment do
    count = Bag.destroy_all
    puts "Destoryed #{count} bags"
  end

end
