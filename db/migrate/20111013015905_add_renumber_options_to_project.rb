class AddRenumberOptionsToProject < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :renumber_features, :boolean
      t.column :renumber_chores, :boolean
      t.column :renumber_bugs, :boolean
      t.column :renumber_releases, :boolean
      t.column :feature_prefix, :string, :limit => 5
      t.column :chore_prefix, :string, :limit => 5
      t.column :bug_prefix, :string, :limit => 5
      t.column :release_prefix, :string, :limit => 5
    end
  end

  def self.down
    remove_column :projects, :renumber_features
    remove_column :projects, :renumber_chores
    remove_column :projects, :renumber_bugs
    remove_column :projects, :renumber_releases
    remove_column :projects, :feature_prefix
    remove_column :projects, :chore_prefix
    remove_column :projects, :bug_prefix
    remove_column :projects, :release_prefix
    end
end
