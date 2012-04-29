class SwitchNumberBoolsToEnums < ActiveRecord::Migration
  def up
    remove_column :projects, :renumber_features
    remove_column :projects, :renumber_chores
    remove_column :projects, :renumber_bugs
    remove_column :projects, :renumber_releases

    change_table :projects do |t|
      t.column :renumber_features, :integer, :default => 0, :null => false
      t.column :renumber_chores, :integer, :default => 0, :null => false
      t.column :renumber_bugs, :integer, :default => 0, :null => false
      t.column :renumber_releases, :integer, :default => 0, :null => false
    end
  end

  def down
    remove_column :projects, :renumber_features
    remove_column :projects, :renumber_chores
    remove_column :projects, :renumber_bugs
    remove_column :projects, :renumber_releases

    change_table :projects do |t|
      t.column :renumber_features, :boolean
      t.column :renumber_chores, :boolean
      t.column :renumber_bugs, :boolean
      t.column :renumber_releases, :boolean
    end
  end
end
