class AddTimeZoneToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.column :time_zone, :string, :null => false, :default => 'Eastern Time (US & Canada)', :limit => 50
    end
  end

  def self.down
    remove_column :users, :time_zone
  end
end
