class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.integer :pivotal_identifier , :null => false
      t.string :description , :limit => 200
      t.float :total_hours
      t.float :remaining_hours
      t.string :status , :limit => 20
      t.boolean :qa , :default => false, :null => false
      t.column :task_estimates_count, :integer, :default => 0
      t.timestamps
    end

    change_table :tasks do |t|
      t.references :story, :null => false
      t.foreign_key :stories, :dependent => :delete
    end
  end

  def self.down
    drop_table :tasks
  end
end
