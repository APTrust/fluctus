class AddFileFormat < ActiveRecord::Migration
  def change
    add_column :io_aggregations, :file_format, :string
  end
end
