class AddSlugToProject < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.column :slug, :string, :limit => 200
    end
    add_index :projects, :slug, :unique => true
  end

  def self.down
    remove_index :projects, :slug
    remove_column :projects, :slug
  end
end
