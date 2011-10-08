class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name, :null => false
      t.timestamps
    end
  end

  def self.down
    remove_foreign_key :projects, :column => :tenant_id
    drop_table :projects
  end
end
