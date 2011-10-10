class AddInterationDurationDays < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :iteration_duration_days, :integer, :null => true
      t.column :sync_status, :string, :null => true, :limit => 200
    end
  end

  def self.down
    remove_column :projects, :iteration_duration_days
    remove_column :projects, :sync_status
  end
end
