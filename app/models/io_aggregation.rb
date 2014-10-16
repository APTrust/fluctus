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
      add_to_size(file.size)
    elsif action == 'update'
      change_format(file)
      change_size(file)
    elsif action == 'delete'
      remove_format(file.file_format)
      remove_from_count
      remove_from_size(file.size)
    end
    self.save!
  end

  def add_format(format)
    if self.file_format == '' || self.file_format.nil?
      self.file_format = format
    else
      self.file_format = "#{self.file_format}, #{format}"
    end
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
    pieces = self.file_format.split(', ')
    count = 0
    new_format = ''
    pieces.each do |piece|
      if count == 0 && piece == format
        count = 1
      else
        if new_format == ''
          new_format = piece
        else
          new_format = "#{new_format}, #{piece}"
        end
      end
    end
    self.file_format = new_format
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
    unless parameters[:size].nil? || parameters[:size].to_i == gf.size.to_i
      add_to_size(parameters[:size])
      remove_from_size(gf.size)
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
    pieces = self.file_format.split(', ')
    format_map = {}
    pieces.each do |piece|
      unless piece == ""
        if format_map.include? piece
          count = format_map[piece]
          count = count + 1
          format_map[piece] = count
        else
          format_map[piece] = 1
        end
      end
    end
    format_map
  end

  def formats_for_solr
    pieces = self.file_format.split(', ')
    format_map = ''
    pieces.each do |piece|
      unless format_map == ''
        format_map = "#{format_map} #{piece}"
      else
        format_map = piece
      end
    end
    format_map
  end
end
