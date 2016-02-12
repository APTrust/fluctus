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

    # Last touched is a timestamp set by microservices which
    # describes when the service was last working on this item.
    add_column :processed_items, :last_touched, :datetime, null: true

    # How many times have we attempted this stage of the processing
    # for this item? This will be reset at each stage.
    add_column :processed_items, :attempt_number, :integer, null: false, default: 0

    # Is this item pending assignment? This timestamp will be set when
    # a microservice asks about items needing processing and
    # cleared when the microservice confirms or denies it can process
    # an item by sending back the processed_item.id with a yes or no.
    add_column :processed_items, :assignment_pending_since, :datetime, null: true
  end
end
