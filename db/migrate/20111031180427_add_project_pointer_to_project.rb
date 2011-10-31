class AddProjectPointerToProject < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.integer :master_project_id, :null => :true, :references => :projects
      t.integer :linked_projects_count, :default => 0
      t.foreign_key :projects, :column => 'master_project_id'
    end
    add_index(:projects, :master_project_id)
  end

  def self.down
    remove_index(:projects, :master_project_id)
    change_table :projects do |t|
      t.remove_foreign_key :projects, :column => 'master_project_id'
    end
    remove_column :projects, :master_project_id
    remove_column :projects, :linked_projects_count
  end
end
