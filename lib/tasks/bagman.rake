namespace :bagman do

  desc "Import data from bagman json log"
  task :import, [:json_file] => [:environment] do |t, args|
    institutions = get_institutions
    File.open(args[:json_file]).each do |line|
      data = JSON.parse(line)
      if data['Error'].nil?
        obj = create_intellectual_object(data, institutions)
        puts obj.inspect
      else
        puts("Skipping #{data['S3File']['Key']['Key']} because " +
             "bag import failed with this error: #{data['Error']}")
      end
    end
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
    title, rights, description = get_title_rights_and_desc(data)
    inst_name = data['S3File']['BucketName'].sub('aptrust.receiving.', '')
    bag_name = data['S3File']['Key']['Key'].sub(/\.tar$/, '')
    #identifier = "#{inst_name}.#{bag_name}"
    identifier = bag_name  # exact format TBD
    ensure_institution(inst_name, institutions)
    institution = institutions[inst_name]
    int_obj = IntellectualObject.new(institution: institution,
                                     title: title,
                                     description: description,
                                     rights: rights,
                                     identifier: identifier)
    add_generic_files(data, int_obj)
    int_obj
  end

  # Parse all the GenericFile records out of the JSON structure
  # and add each generic file to the intellectual object.
  def add_generic_files(data, int_obj)
    data['BagReadResult']['GenericFiles'].each do |gf|
      int_obj.generic_files << new_generic_file(gf, int_obj)
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
                           created: gf['Created'].gsub(' ', ''), #Time.parse(gf['Created'].gsub(' ', '')),
                           modified: gf['Modified'].gsub(' ', '')) #Time.parse(gf['Modified'].gsub(' ', '')))
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
    file.add_event(new_identifier_assignment(gf['Uuid']))
    file.add_event(new_fixity_check(gf['Md5']))
    file.add_event(new_fixity_generation(gf['Sha256']))
    file.save!
    file
  end


  # Returns a new identifier_assignment event with the specified
  # identifier.
  def new_identifier_assignment(identifier)
    {
      type: "identifier_assignment",
      date_time: Time.now.to_s,
      detail: "S3 key generated for file",
      outcome: "success",
      outcome_detail: identifier,
      outcome_information: "Generated with github.com/nu7hatch/gouuid",
      object: "go 1.2.1",
      agent: "http://golang.org",
    }
  end

  # Returns a new fixity_check event with the specified
  # md5 sum.
  def new_fixity_check(md5sum)
    {
      type: "fixity_check",
      date_time: Time.now.to_s,
      detail: "Fixity check against registered md5 hash",
      outcome: "success",
      outcome_detail: md5sum,
      outcome_information: "Fixity matches",
      object: "go 1.2.1 crypto/md5",
      agent: "http://golang.org",
    }
  end

  # Returns a new fixity_generation event with the specified
  # sha256 sum.
  def new_fixity_generation(sha256sum)
    {
      type: "fixity_generation",
      date_time: Time.now.to_s,
      detail: "Calculated new fixity value",
      outcome: "success",
      outcome_detail: sha256sum,
      #outcome_information: "",
      object: "go 1.2.1 crypto/md5",
      agent: "http://golang.org",
    }
  end


  # Extracts the title, rights and description for the intellectual object
  # from the Go data. If rights were not specified in the bag file, we
  # default to the most conservative: 'restricted'.
  #
  # Our bag specification says to use values Consortia, Institution, or
  # Restricted. Our Ruby spec says to use consortial, institution or
  # restricted. This method converts the bag values to the Ruby values.
  # It fixes the difference in case and converts "Consortia" to "consortial".
  def get_title_rights_and_desc(data)
    rights = 'restricted'
    title = nil
    description = nil
    data['BagReadResult']['Tags'].each do |tag|
      label = tag['Label']
      if label == 'Title'
        title = tag['Value']
      elsif label == 'Rights'
        _rights = tag['Value']
        if !_rights.nil?
          _rights = _rights.downcase
          if _rights.start_with?('consortia')
            _rights = 'consortial'
          end
          rights = _rights
        end
      elsif label == 'Internal-Sender-Description'
        description = tag['Value']
      end
    end
    return title, rights, description
  end

end
