class CreateLogons < ActiveRecord::Migration
  def self.up
    create_table :logons do |t|
      t.references :user, :null => false
      t.string :ip_address, :null => false
      t.timestamps
    end

    change_table :logons do |t|
      t.foreign_key :users, :dependent => :delete
    end

    add_column :users, :logons_count, :integer, :default => 0
  end

  def self.down
    drop_table :logons
  end
end
