class CreateCardRequests < ActiveRecord::Migration
  def self.up
    create_table :card_requests do |t|
      t.column :cards_count, :integer, :default => 0
      t.timestamps
    end

    change_table :card_requests do |t|
      t.references :user, :null => :false
      t.foreign_key :users, :dependent => :delete
    end
  end

  def self.down
    drop_table :card_requests
  end
end
