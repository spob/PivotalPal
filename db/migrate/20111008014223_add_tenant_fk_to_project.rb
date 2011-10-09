class AddTenantFkToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :pivotal_identifier, :integer, :null => false
    add_index :projects, [:tenant_id, :name], :unique => true
  end

  def self.down
    remove_index :projects, [:tenant_id, :name]
    remove_column :projects, :pivotal_identifier
  end
end
