class AddReviewedToProcessedItem < ActiveRecord::Migration
  def change
    add_column :processed_items, :reviewed, :boolean
  end
end
