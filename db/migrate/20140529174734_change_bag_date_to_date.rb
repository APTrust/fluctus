class ChangeBagDateToDate < ActiveRecord::Migration
  def change
    change_column(:processed_items, :bag_date, :datetime)
  end
end
