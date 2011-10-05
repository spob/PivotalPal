class AddTemporaryPasswordToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.column :temporary_password, :string, :null => true
    end
  end

  def self.down
    remove_column :users, :temporary_password
  end
end
