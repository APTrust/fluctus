class AddObjectIdentifierToProcessedItems < ActiveRecord::Migration
  def change
    add_column :processed_items, :object_identifier, :string
  end
end
