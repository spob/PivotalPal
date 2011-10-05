class AddTenantToPosition < ActiveRecord::Migration
  def self.up
    change_table :categories do |t|
      t.references :tenant, :null => false
      t.foreign_key :tenants, :dependent => :delete
    end
  end

  def self.down
    remove_column :categories, :tenant_id
  end
end
