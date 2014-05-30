class ProcessedItemDatesToDatetimes < ActiveRecord::Migration
  def change
    change_column(:processed_items, :date, :datetime)
  end
end
