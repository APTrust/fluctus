namespace :bagman do

  desc "Import data from bagman json log"
  task :import, [:json_file] => [:environment] do |t, args|
    start = Time.now
    imported = 0
    institutions = get_institutions
    File.open(args[:json_file]).each do |line|
      data = JSON.parse(line)
      if data['Error'].nil?
        obj = create_intellectual_object(data, institutions)
        puts obj.inspect
        imported += 1
      else
        puts("Skipping #{data['S3File']['Key']['Key']} because " +
             "bag import failed with this error: #{data['Error']}")
      end
    end
    finish = Time.now
    puts("Imported #{imported} records in #{finish - start}")
  end

  # Returns a hash of institutions that already exist. Key is
  # institution name, value is Institution object. We need this
  # to determine whether we need to create a new institution
  # for some record we just imported from the bagman log.
  def get_institutions
    institutions = {}
    Institution.all.each do |inst|
      institutions[inst.name] = inst
    end
    institutions
  end

  # Make sure the institution with the specified name exists.
  # Create it if necessary.
  def ensure_institution(name, institutions)
    if institutions[name].nil?
      inst = Institution.create!(name: name)
      institutions[name] = inst
      puts "Created institution #{name}"
    end
  end

  # Creates and saves an intellectual object from a data structure
  # in the bagman JSON log. Each line in that log is a single
  # JSON record, and each record contains info about a single
  # intellectual object.
  def create_intellectual_object(data, institutions)
    title, access, description = get_title_access_and_desc(data)
    inst_name = data['S3File']['BucketName'].sub('aptrust.receiving.', '')
    bag_name = data['S3File']['Key']['Key'].sub(/\.tar$/, '')
    #identifier = "#{inst_name}.#{bag_name}"
    identifier = bag_name  # exact format TBD
    ensure_institution(inst_name, institutions)
    institution = institutions[inst_name]
    int_obj = IntellectualObject.new(institution: institution,
                                     title: title,
                                     description: description,
                                     access: access,
                                     identifier: identifier)
    add_generic_files(data, int_obj)
    int_obj
  end

  # Parse all the GenericFile records out of the JSON structure
  # and add each generic file to the intellectual object.
  def add_generic_files(data, int_obj)
    data['TarResult']['GenericFiles'].each do |gf|
      begin
        int_obj.generic_files << new_generic_file(gf, int_obj)
      rescue StandardError => ex
        puts "Error creating generic file #{gf['Path']}: #{ex}"
      end
    end
  end

  # This parses a single generic file record from the JSON data
  # and returns a GenericFile object.
  def new_generic_file(gf, int_obj)
    uri_prefix = "https://s3.amazon.aws.com/aptrust.storage.#{int_obj.institution.name}/"
    file = GenericFile.new(intellectual_object: int_obj,
                           format: gf['MimeType'],
                           uri: uri_prefix + gf['Path'],
                           size: gf['Size'],
                           created: gf['Created'].gsub(' ', ''),
                           modified: gf['Modified'].gsub(' ', ''))
    file.techMetadata.checksum.build({
                     algorithm: 'md5',
                     datetime: Time.now.to_s,
                     digest: gf['Md5']
                 })
    file.techMetadata.checksum.build({
                     algorithm: 'sha256',
                     datetime: Time.now.to_s,
                     digest: gf['Sha256']
                 })
    file.save!
    file.add_event(new_identifier_assignment(gf['Uuid'],
                                             gf['UuidGenerated']))
    file.add_event(new_fixity_generation(gf['Sha256'],
                                         gf['Sha256Generated']))
    file.save!
    file
  end


  # Returns a new identifier_assignment event with the specified
  # identifier.
  def new_identifier_assignment(identifier, timestamp)
    {
      type: "identifier_assignment",
      date_time: timestamp,
      detail: "S3 key generated for file",
      outcome: "success",
      outcome_detail: identifier,
      outcome_information: "Generated with github.com/nu7hatch/gouuid",
      object: "go 1.2.1",
      agent: "http://golang.org",
    }
  end

  # Returns a new fixity_generation event with the specified
  # sha256 sum.
  def new_fixity_generation(sha256sum, timestamp)
    {
      type: "fixity_generation",
      date_time: timestamp,
      detail: "Calculated new fixity value",
      outcome: "success",
      outcome_detail: sha256sum,
      #outcome_information: "",
      object: "go 1.2.1 crypto/md5",
      agent: "http://golang.org",
    }
  end


  # Extracts the title, access and description for the intellectual object
  # from the Go data. If access were not specified in the bag file, we
  # default to the most conservative: 'restricted'.
  #
  # Our bag specification says to use values Consortia, Institution, or
  # Restricted. Our Ruby spec says to use consortial, institution or
  # restricted. This method converts the bag values to the Ruby values.
  # It fixes the difference in case and converts "Consortia" to "consortial".
  def get_title_access_and_desc(data)
    access = 'restricted'
    title = nil
    description = nil
    data['BagReadResult']['Tags'].each do |tag|
      label = tag['Label']
      if label == 'Title'
        title = tag['Value']
      elsif label == 'Rights'
        _access = tag['Value']
        if !_access.nil?
          _access = _access.downcase
          if _access.start_with?('consortia')
            _access = 'consortial'
          end
          access = _access
        end
      elsif label == 'Internal-Sender-Description'
        description = tag['Value']
      end
    end
    return title, access, description
  end

end
