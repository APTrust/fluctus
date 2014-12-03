class AddPurgeToProcessedItem < ActiveRecord::Migration
  def change
    add_column :processed_items, :purge, :boolean
  end
end
