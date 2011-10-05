class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name, :null => false
      t.timestamps
    end
    add_index :categories, [:tenant_id, :name],                :unique => true
  end

  def self.down
    remove_foreign_key :categories, :column => :tenant_id
    drop_table :categories
  end
end
