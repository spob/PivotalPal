class AddTenantFkToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.references :tenant
      t.foreign_key :tenants, :dependent => :delete
    end
  end

  def self.down
    remove_column :users, :tenant_id
  end
end
