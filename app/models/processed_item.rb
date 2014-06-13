class ProcessedItem < ActiveRecord::Base

  paginates_per 10

  validates :name, :etag, :bag_date, :bucket, :user, :institution, :date, :note, :action, :stage, :status, :outcome, presence: true

  def to_param
    "#{etag}/#{name}"
  end

end
