class CreateUsageSamples < ActiveRecord::Migration
  def change
    create_table :usage_samples do |t|
      t.string :institution_id, index: true
      t.text :data

      t.timestamps
    end
  end
end
