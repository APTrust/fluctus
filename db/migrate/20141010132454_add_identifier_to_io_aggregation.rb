class AddIdentifierToIoAggregation < ActiveRecord::Migration
  def change
    add_column :io_aggregations, :identifier, :string
  end
end
