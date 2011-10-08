class AddTenantFkToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :project_identifier, :integer, :null => false
    add_index :projects, [:tenant_id, :name], :unique => true
  end

  def self.down
    remove_index :projects, [:tenant_id, :name]
    remove_column :projects, :project_identifier
  end
end
