class AddDescriptionToStory < ActiveRecord::Migration
  def self.up
    change_table :stories do |t|
      t.column :body, :text
    end
  end

  def self.down
    remove_column :stories, :body
  end
end
