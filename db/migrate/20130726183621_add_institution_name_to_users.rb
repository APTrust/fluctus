class AddInstitutionNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :institution_name, :string
  end
end
