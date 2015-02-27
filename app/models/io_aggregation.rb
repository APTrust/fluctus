class IoAggregation < ActiveRecord::Base

  #validates :file_count, :file_size, :file_format, :identifier, presence: true

  def initialize_object(id)
    self.file_count = 0
    self.file_size = 0
    self.file_format = ''
    self.identifier = id
  end

  def update_aggregations(action, file)
    if action == 'add'
      add_format(file.file_format)
      add_to_count
      add_to_size(file.file_size)
    elsif action == 'update'
      change_format(file)
      change_size(file)
    elsif action == 'delete'
      remove_format(file.file_format)
      remove_from_count
      remove_from_size(file.file_size)
    end
    self.save!
    io = get_intellectual_object
    io.update_index
  end

  def update_aggregations_solr
    row = 1000000
    start = 0
    query ||= []
    query << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{self.identifier}")
    solr_result = ActiveFedora::SolrService.query(query, :rows => row, :start => start)
    total_files = solr_result.count
    formats = ''
    size = 0
    solr_result.each do |file|
      unless file['object_state_ssi'] == 'D'
        current_format = file['tech_metadata__file_format_ssi']
        (formats == '' || formats.nil?) ? formats = current_format : formats = "#{formats},#{current_format}"
        current_size = file['tech_metadata__file_size_lsi'].to_i
        size = size + current_size
      end
    end
    self.file_count = total_files
    self.file_size = size
    self.file_format = formats
    self.save!
    io = get_intellectual_object
    io.update_index
  end

  def add_format(format)
    (self.file_format == '' || self.file_format.nil?) ? self.file_format = format : self.file_format = "#{self.file_format},#{format}"
  end

  def change_format(file)
    gf = file[0]
    parameters = file[1]
    unless parameters[:file_format].nil? || parameters[:file_format] == gf.file_format
      add_format(parameters[:file_format])
      remove_format(gf.file_format)
    end
  end

  def remove_format(format)
    format_array = self.file_format.split(',')
    format_array = format_array - [format]
    self.file_format = format_array.join(',')
  end

  def add_to_count
    count = self.file_count
    count = count+1
    self.file_count = count
  end

  def remove_from_count
    count = self.file_count
    count = count-1
    self.file_count = count
  end

  def add_to_size(size)
    new_size = self.file_size
    new_size = new_size + size.to_i
    self.file_size = new_size
  end

  def change_size(file)
    gf = file[0]
    parameters = file[1]
    unless parameters[:file_size].nil? || parameters[:file_size].to_i == gf.file_size.to_i
      add_to_size(parameters[:file_size])
      remove_from_size(gf.file_size)
    end
  end

  def remove_from_size(size)
    new_size = self.file_size
    new_size = new_size - size.to_i
    self.file_size = new_size
  end

  def get_intellectual_object
    io = IntellectualObject.find(self.identifier)
    io
  end

  def format_to_map
    format_map = {}
    format_array = self.file_format.split(',')
    format_array.each do |format|
      if format_map.include?(format)
        count = format_map[format]
        count = count + 1
        format_map[format] = count
      else
        format_map[format] = 1
      end
    end
    format_map
  end

  def formats_for_solr
    unless self.file_format.nil?
      pieces = self.file_format.split(',')
      format_map = []
      pieces.each do |piece|
        unless format_map.include?(piece) || piece == ''
          format_map.push(piece)
        end
      end
      format_map
    end
  end
end
