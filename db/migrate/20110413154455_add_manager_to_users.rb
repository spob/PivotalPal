class AddManagerToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.column :manager_id, :integer, :null => true, :references => :user
      t.foreign_key(:users, :column => :manager_id)
    end
  end

  def self.down
    remove_foreign_key :users, :column => :manager_id
    remove_column :users, :manager_id
  end
end
