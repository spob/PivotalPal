class AddHiredateToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.column :hired_at, :date, :null => true
    end
  end

  def self.down
    remove_column :users, :hired_at
  end
end
