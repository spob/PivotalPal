class AddTenantToPosition < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.references :tenant, :null => false
      t.foreign_key :tenants, :dependent => :delete
    end
  end

  def self.down
    remove_column :projects, :tenant_id
  end
end
