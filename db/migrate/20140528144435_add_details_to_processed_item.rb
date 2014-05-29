class AddDetailsToProcessedItem < ActiveRecord::Migration
  def change

    add_column :processed_items, :name, :string
    add_column :processed_items, :etag, :string
    add_column :processed_items, :bag_date, :string
    add_column :processed_items, :bucket, :string
    add_column :processed_items, :user, :string
    add_column :processed_items, :institution, :string
    add_column :processed_items, :date, :string
    add_column :processed_items, :note, :string
    add_column :processed_items, :action, :string
    add_column :processed_items, :stage, :string
    add_column :processed_items, :status, :string
    add_column :processed_items, :outcome, :string

    add_index :processed_items, [:etag, :name]
    add_index :processed_items, :date
    add_index :processed_items, :action
    add_index :processed_items, :institution
    add_index :processed_items, :stage
    add_index :processed_items, :status


  end
end
