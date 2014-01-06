module RecordsHelper
  include RecordsHelperBehavior
  # Override Hydra::Editor to make it post to the IntellectualObjectsController
  def record_form_action_url(record)
    record.new_record? ? intellectual_objects_path : intellectual_object_path(record)
  end

end
