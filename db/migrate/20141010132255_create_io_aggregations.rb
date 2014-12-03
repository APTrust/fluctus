class CreateIoAggregations < ActiveRecord::Migration
  def change
    create_table :io_aggregations do |t|
      t.float :file_size
      t.string :file_format
      t.integer :file_count

      t.timestamps
    end
  end
end
