class AddTenantFkToProject < ActiveRecord::Migration
  def self.up
    add_index :projects, [:tenant_id, :name],                :unique => true
  end

  def self.down
    remove_index :projects, [:tenant_id, :name]
  end
end
