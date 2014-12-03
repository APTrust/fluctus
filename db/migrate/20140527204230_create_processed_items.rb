class CreateProcessedItems < ActiveRecord::Migration
  def change
    create_table :processed_items do |t|

      t.timestamps
    end
  end
end
