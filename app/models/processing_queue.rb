class ProcessingQueue < ActiveRecord::Base

  #has_attributes :table, multiple: false
  validates :table, presence: true

end
