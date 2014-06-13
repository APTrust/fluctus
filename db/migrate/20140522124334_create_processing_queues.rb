class CreateProcessingQueues < ActiveRecord::Migration
  def change
    create_table :processing_queues do |t|

      t.timestamps
    end
  end
end
