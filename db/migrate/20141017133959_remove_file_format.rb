class RemoveFileFormat < ActiveRecord::Migration
  def change
    remove_column :io_aggregations, :file_format, :string
  end
end
