class DefaultReviewedStatus < ActiveRecord::Migration
  def change
    change_column :processed_items, :reviewed, :boolean, :default => false
  end
end
