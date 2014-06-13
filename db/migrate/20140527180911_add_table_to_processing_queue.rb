class AddTableToProcessingQueue < ActiveRecord::Migration
  def change
    add_column :processing_queues, :table, :text #:array
  end
end
