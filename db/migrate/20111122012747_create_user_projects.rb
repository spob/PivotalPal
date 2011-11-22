class CreateUserProjects < ActiveRecord::Migration
  def self.up
    create_table :user_projects do |t|
      t.references :user, :null => false
      t.references :project, :null => false
      t.datetime :read_at, :null => false
      t.timestamps
    end

    change_table :user_projects do |t|
      t.foreign_key :users, :dependent => :delete
      t.foreign_key :projects, :dependent => :delete
    end

    add_column :users, :user_projects_count, :integer, :default => 0
    add_column :projects, :user_projects_count, :integer, :default => 0
  end

  def self.down
    remove_column :users, :user_projects_count
    remove_column :projects, :user_projects_count
    drop_table :user_projects
  end
end
