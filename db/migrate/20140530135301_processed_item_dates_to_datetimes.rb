class ProcessedItemDatesToDatetimes < ActiveRecord::Migration
  def change
    remove_column(:processed_items, :date)
    add_column(:processed_items, :date, :datetime)
  end
end
