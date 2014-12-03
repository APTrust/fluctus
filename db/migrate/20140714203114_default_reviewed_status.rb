class DefaultReviewedStatus < ActiveRecord::Migration
  def up
    change_column :processed_items, :reviewed, :boolean, :default => false
  end
  def down
    change_column :processed_items, :reviewed, :boolean
  end
end
