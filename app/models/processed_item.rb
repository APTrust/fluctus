class ProcessedItem < ActiveRecord::Base

  paginates_per 10

  validates :name, :etag, :bag_date, :bucket, :user, :institution, :date, :note, :action, :stage, :status, :outcome, presence: true
  validate :status_is_allowed
  validate :stage_is_allowed
  validate :action_is_allowed

  def to_param
    "#{etag}/#{name}"
  end

  def status_is_allowed
    if !Fluctus::Application::PROC_ITEM_STATUSES.include?(self.status)
      errors.add(:status, 'Status is not one of the allowed options')
    end
  end

  def stage_is_allowed
    if !Fluctus::Application::PROC_ITEM_STAGES.include?(self.stage)
      errors.add(:stage, 'Stage is not one of the allowed options')
    end
  end

  def action_is_allowed
    if !Fluctus::Application::PROC_ITEM_ACTIONS.include?(self.action)
      errors.add(:action, 'Action is not one of the allowed options')
    end
  end

end
