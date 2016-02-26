class AddQueueColumns < ActiveRecord::Migration
  def change
    # The state column contains a blob of JSON that details
    # the state of the item during processing. This JSON also
    # contains information useful for auditing. Eventually,
    # this data may be stored in proper structured SQL format,
    # but for now, we just need a place for our services to
    # store and retrieve it
    add_column :processed_items, :state, :text, null: true

    # Node the IP address of the node that is currently
    # processing this item.
    add_column :processed_items, :node, :string, null: true, limit: 40

    # The id of the process on the node that is currently
    # processing this item. (This is the pid you'd see in top.)
    add_column :processed_items, :pid, :integer, null: false, default: 0

    # Does this item need admin review? If so, processing should
    # stop until it's cleared.
    add_column :processed_items, :needs_admin_review, :boolean, null: false, default: false

    # Why do we have to do this? Is it just SQLite?
    ProcessedItem.where("pid is null").update_all(pid: 0)
  end
end
