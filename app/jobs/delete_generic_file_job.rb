class DeleteGenericFileJob
  attr_accessor :generic_file_id

  def initialize(generic_file_id)
    self.generic_file_id = generic_file_id
  end

  def run
    # TODO the delete action goes here
  end
end
