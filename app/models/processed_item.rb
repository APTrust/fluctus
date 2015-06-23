class ProcessedItem < ActiveRecord::Base

  paginates_per 10

  validates :name, :etag, :bag_date, :bucket, :user, :institution, :date, :note, :action, :stage, :status, :outcome, presence: true
  validate :status_is_allowed
  validate :stage_is_allowed
  validate :action_is_allowed
  validate :reviewed_not_nil
  before_save :set_object_identifier_if_ingested

  def to_param
    "#{etag}/#{name}"
  end

  def self.pending?(intellectual_object_identifier)
    items = ProcessedItem.where(object_identifier: intellectual_object_identifier )
    items = items.order('date DESC')
    pending = 'false'
    items.each do |item|
      if item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] ||
          item.status == Fluctus::Application::FLUCTUS_STATUSES['fail'] ||
          item.status == Fluctus::Application::FLUCTUS_STATUSES['cancel']
        pending = 'false'
      else
         if item.action == Fluctus::Application::FLUCTUS_ACTIONS['ingest']
           pending = 'ingest'
           break
         elsif item.action == Fluctus::Application::FLUCTUS_ACTIONS['restore']
           pending = 'restore'
           break
         elsif item.action == Fluctus::Application::FLUCTUS_ACTIONS['delete']
           pending = 'delete'
           break
         elsif item.action == Fluctus::Application::FLUCTUS_ACTIONS['dpn']
           pending = 'dpn'
           break
         end
      end
    end
    pending
  end

  def self.can_delete_file?(intellectual_object_identifier, generic_file_identifier)
    items = ProcessedItem.where(object_identifier: intellectual_object_identifier)
    items = items.order('date DESC')
    result = 'true'
    items.each do |item|
      if item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] ||
          item.status == Fluctus::Application::FLUCTUS_STATUSES['fail'] ||
          item.status == Fluctus::Application::FLUCTUS_STATUSES['cancel']
        result = 'true'
      else
        if item.action == Fluctus::Application::FLUCTUS_ACTIONS['ingest']
          result = 'ingest'
          break
        elsif item.action == Fluctus::Application::FLUCTUS_ACTIONS['restore']
          result = 'restore'
          break
        elsif item.action == Fluctus::Application::FLUCTUS_ACTIONS['delete'] && item.generic_file_identifier == generic_file_identifier
          result = 'delete'
          break
        end
      end
    end
    result
  end

  # Returns the ProcessedItem record for the last successfully ingested
  # version of an intellectual object. The last ingested version has
  # these characteristicts:
  #
  # * Action is Ingest
  # * Stage is Clean or (Stage is Record and Status is Success)
  # * Has the latest date of any record with the above characteristics
  def self.last_ingested_version(intellectual_object_identifier)
    items = ProcessedItem.where(object_identifier: intellectual_object_identifier, action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                stage: Fluctus::Application::FLUCTUS_STAGES['clean']).order('date DESC').limit(1).first
    if items.nil?
      items = ProcessedItem.where(object_identifier: intellectual_object_identifier, action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                  stage: Fluctus::Application::FLUCTUS_STAGES['record'], status: Fluctus::Application::FLUCTUS_STATUSES['success']).order('date DESC').limit(1).first
    end
    items
  end

  # Creates a ProcessedItem record showing that someone has requested
  # restoration of an IntellectualObject. This will eventually go into
  # a queue for the restoration worker process.
  def self.create_restore_request(intellectual_object_identifier, requested_by)
    item = ProcessedItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    restore_item = item.dup
    restore_item.action = Fluctus::Application::FLUCTUS_ACTIONS['restore']
    restore_item.stage = Fluctus::Application::FLUCTUS_STAGES['requested']
    restore_item.status = Fluctus::Application::FLUCTUS_STATUSES['pend']
    restore_item.note = 'Restore requested'
    restore_item.outcome = 'Not started'
    restore_item.user = requested_by
    restore_item.retry = true
    restore_item.reviewed = false
    restore_item.date = Time.now
    restore_item.save!
    restore_item
  end

  def self.create_dpn_request(intellectual_object_identifier, requested_by)
    item = ProcessedItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    dpn_item = item.dup
    dpn_item.action = Fluctus::Application::FLUCTUS_ACTIONS['dpn']
    dpn_item.stage = Fluctus::Application::FLUCTUS_STAGES['requested']
    dpn_item.status = Fluctus::Application::FLUCTUS_STATUSES['pend']
    dpn_item.note = 'Requested item be sent to DPN'
    dpn_item.outcome = 'Not started'
    dpn_item.user = requested_by
    dpn_item.retry = true
    dpn_item.reviewed = false
    dpn_item.date = Time.now
    dpn_item.save!
    dpn_item
  end

  # Creates a ProcessedItem record showing that someone has requested
  # deletion of a GenericFile. This will eventually go into a queue for
  # the delete worker process.
  def self.create_delete_request(intellectual_object_identifier, generic_file_identifier, requested_by)
    item = ProcessedItem.last_ingested_version(intellectual_object_identifier)
    if item.nil?
      raise ActiveRecord::RecordNotFound
    end
    delete_item = item.dup
    delete_item.action = Fluctus::Application::FLUCTUS_ACTIONS['delete']
    delete_item.stage = Fluctus::Application::FLUCTUS_STAGES['requested']
    delete_item.status = Fluctus::Application::FLUCTUS_STATUSES['pend']
    delete_item.note = 'Delete requested'
    delete_item.outcome = 'Not started'
    delete_item.user = requested_by
    delete_item.retry = true
    delete_item.reviewed = false
    delete_item.date = Time.now
    delete_item.generic_file_identifier = generic_file_identifier
    delete_item.save!
    delete_item
  end


  def status_is_allowed
    if !Fluctus::Application::FLUCTUS_STATUSES.values.include?(self.status)
      errors.add(:status, 'Status is not one of the allowed options')
    end
  end

  def stage_is_allowed
    if !Fluctus::Application::FLUCTUS_STAGES.values.include?(self.stage)
      errors.add(:stage, 'Stage is not one of the allowed options')
    end
  end

  def action_is_allowed
    if !Fluctus::Application::FLUCTUS_ACTIONS.values.include?(self.action)
      errors.add(:action, 'Action is not one of the allowed options')
    end
  end

  def reviewed_not_nil
    self.reviewed = false if self.reviewed.nil?
  end

  def ingested?
    ingest = Fluctus::Application::FLUCTUS_ACTIONS['ingest']
    record = Fluctus::Application::FLUCTUS_STAGES['record']
    clean = Fluctus::Application::FLUCTUS_STAGES['clean']
    success = Fluctus::Application::FLUCTUS_STATUSES['success']

    if self.action.blank? == false && self.action != ingest
      # we're past ingest
      return true
    elsif self.action == ingest && self.stage == record && self.status == success
      # we just finished successful ingest
      return true
    elsif self.action == ingest && self.stage == clean
      # we finished ingest and processor is cleaning up
      return true
    end
    # if we get here, we're in some stage of the ingest process,
    # but ingest is not yet complete
    return false
  end

  private

  # ProcessedItem will not have an object identifier until
  # it has been ingested.
  def set_object_identifier_if_ingested
    if self.object_identifier.blank? && self.ingested?
      # Suffixes for single-part and multi-part bags
      re_single = /\.tar$/
      re_multi = /\.b\d+\.of\d+$/
      bag_basename = self.name.sub(re_single, '').sub(re_multi, '')
      self.object_identifier = "#{self.institution}/#{bag_basename}"
    end
  end

end
