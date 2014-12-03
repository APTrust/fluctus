class ProcessedItemsGfIdentifier < ActiveRecord::Migration
  def change
    add_column :processed_items, :generic_file_identifier, :string
  end
end
