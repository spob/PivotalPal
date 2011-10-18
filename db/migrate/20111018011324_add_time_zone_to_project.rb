class AddTimeZoneToProject < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :time_zone, :string, :limit => 50,  :default => "Eastern Time (US & Canada)", :null => false
    end
  end

  def self.down
    remove_column :projects, :time_zone
  end
end
