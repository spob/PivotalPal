class CreatePools < ActiveRecord::Migration
  def self.up
    create_table :pools do |t|
      t.string :name, :null => false, :limit => 20
      # Is this pool limited (e.g. vacation) or unlimited (e.g. bereavement)
      t.boolean :unlimited, :null => false
      # Does the amount of time off increase over time and by how much (e.g., 1 day a year)
      t.integer :increase_rate, :null => true
      # No increase, annual on a set date, annual based on anniversary
      t.string :increase_type, :null => true
      # If the increase is set to annual on a set date, how many days into the year does the increase occur?
      t.integer :increase_day_number, :null => true
      # What is the maximum increase rate allowed?
      t.float :maximum_accrual_rate, :null => true
      # The day of the month when accruals occur
      t.integer :accrual_day_number, :null => true
      t.references :tenant, :null => false
      t.timestamps
      end
    add_foreign_key(:pools, :tenants, :dependent => :delete)
    add_index :pools, [:tenant_id, :name],                :unique => true

    change_table :tenants do |t|
      t.integer :pools_count, :default => 0
    end
  end

  def self.down
    remove_foreign_key :pools, :column => :tenant_id
    drop_table :pools
    remove_column :tenants, :pools_count
  end
end
