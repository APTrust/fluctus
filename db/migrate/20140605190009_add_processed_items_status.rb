class AddProcessedItemsStatus < ActiveRecord::Migration
  def change
    add_column(:processed_items, :retry, :boolean, :null => false, :default => false)
    change_column(:processed_items, :note, :text, :null => true)
    change_column(:processed_items, :outcome, :text, :null => true)
  end
end
