class ProcessedItem < ActiveRecord::Base

  validates :name, :etag, :datetime, :bucket, :user, :institution, :date, :note, :action, :stage, :status, :outcome, presence: true

  def to_param
    "#{etag}/#{name}"
  end

end
