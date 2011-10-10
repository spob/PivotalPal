class CreateStories < ActiveRecord::Migration
  def self.up
    create_table "stories", :force => true do |t|
      t.integer "pivotal_identifier", :null => false
      t.string "story_type", :null => false, :limit => 10
      t.string "url", :null => false, :limit => 50
      t.integer "points"
      t.string "status", :null => false, :limit => 20
      t.string "name", :null => false, :limit => 200
      t.string "owner", :limit => 50
      t.integer "sort"
      t.column :tasks_count, :integer, :default => 0
      t.timestamps
    end

    change_table :stories do |t|
      t.references :iteration, :null => false
      t.foreign_key :iterations, :dependent => :delete
    end

    add_index "stories", ["iteration_id", "pivotal_identifier"], :name => "index_stories_on_iteration_id_and_pivotal_identifier", :unique => true
  end

  def self.down
    drop_table :stories
  end
end
