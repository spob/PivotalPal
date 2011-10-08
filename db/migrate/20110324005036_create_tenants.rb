class CreateTenants < ActiveRecord::Migration
  def self.up
    create_table :tenants do |t|
      t.string :name, :null =>false, :limit => 50
      t.string :api_key, :null =>true, :limit => 32
      t.integer :users_count, :default => 0
      t.integer :projects_count, :default => 0
      t.timestamps
    end
    add_index :tenants, [:name], :unique => true
  end

  def self.down
    drop_table :tenants
  end
end
