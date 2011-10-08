class AddLastSyncedAt < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :last_synced_at, :datetime, :null => true
    end
  end

  def self.down
    remove_column :projects, :last_synced_at
  end
end
