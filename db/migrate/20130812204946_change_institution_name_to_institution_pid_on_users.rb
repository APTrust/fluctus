class ChangeInstitutionNameToInstitutionPidOnUsers < ActiveRecord::Migration
  def change
    rename_column :users, :institution_name, :institution_pid
  end
end
