class AddJiraNumberToStory < ActiveRecord::Migration
  def up
    change_table :stories do |t|
      t.column :jira_number, :string, :limit => 25
    end
  end

  def down
    remove_column :stories, :jira_number
  end
end
