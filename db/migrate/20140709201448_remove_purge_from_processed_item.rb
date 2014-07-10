class RemovePurgeFromProcessedItem < ActiveRecord::Migration
  def change
    remove_column :processed_items, :purge, :boolean
  end
end
