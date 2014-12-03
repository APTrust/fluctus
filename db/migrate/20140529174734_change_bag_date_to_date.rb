class ChangeBagDateToDate < ActiveRecord::Migration
  def change
    remove_column(:processed_items, :bag_date)
    add_column(:processed_items, :bag_date, :datetime)
  end
end
