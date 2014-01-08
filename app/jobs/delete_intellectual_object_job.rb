class DeleteIntellectualObjectJob
  attr_accessor :intellectual_object_id

  def initialize(intellectual_object_id)
    self.intellectual_object_id = intellectual_object_id
  end

  def run
    # TODO the delete action goes here
  end
end

