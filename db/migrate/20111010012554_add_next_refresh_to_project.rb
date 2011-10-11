class AddNextRefreshToProject < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :next_sync_at, :datetime, :null => true
    end
    change_table :tenants do |t|
      t.column :refresh_frequency_hours, :integer, :null => false, :default => 1
    end
  end

  def self.down
    remove_column :projects, :next_sync_at
    remove_column :tenants, :refresh_frequency_hours
  end
end
