class AddNamesToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string :first_name, :length => 25
      t.string :last_name, :length => 25, :null => false
      t.string :company_name, :length => 50, :null => true
      t.string :api_key, :length => 32, :null => true
    end
  end

  def self.down
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :company_name
    remove_column :users, :api_key
  end
end
