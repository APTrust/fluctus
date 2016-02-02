class DropTableIoAggregations < ActiveRecord::Migration
  def change
    drop_table :io_aggregations
  end
end
