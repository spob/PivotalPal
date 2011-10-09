class AddLastSyncedAt < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :last_synced_at, :datetime, :null => true
      t.column :iterations_count, :integer, :default => 0
    end
  end

  def self.down
    remove_column :projects, :last_synced_at
    remove_column :projects, :iterations_count
  end
end
