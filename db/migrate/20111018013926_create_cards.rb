class CreateCards < ActiveRecord::Migration
  def self.up
    create_table :cards do |t|
      t.integer :iteration_number, :null => false
      t.integer :pivotal_identifier, :null => false
      t.string :story_type, :limit => 10, :null => false
      t.string :url, :limit => 50, :null => false
      t.integer :points
      t.string :status, :limit => 20, :null => false
      t.string :name, :limit => 200, :null => false
      t.string :owner, :limit => 50
      t.integer :sort
      t.text :body
      t.timestamps
    end

    change_table :cards do |t|
      t.references :card_request, :null => :false
      t.foreign_key :card_requests, :dependent => :delete
    end
  end

  def self.down
    drop_table :cards
  end
end
