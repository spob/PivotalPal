class RemovePasswordSalt < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
    remove_column :users, :password_salt
    end
  end

  def self.down
      t.column :password_salt, :string, :null => true
  end
end
