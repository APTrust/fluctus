class ChangeFileFormatInIoAggregations < ActiveRecord::Migration
  def change
    change_column :io_aggregations, :file_format, :string
  end
end
