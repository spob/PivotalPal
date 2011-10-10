class CreateIterations < ActiveRecord::Migration
  def self.up
    create_table :iterations do |t|
      t.integer :iteration_number, :null => false
      t.date :start_on, :null => false
      t.date :end_on, :null => false
      t.datetime :last_synced_at
      t.column :stories_count, :integer, :default => 0
      t.column :task_estimates_count, :integer, :default => 0
      t.timestamps
    end

    change_table :iterations do |t|
      t.references :project, :null => false
      t.foreign_key :projects, :dependent => :delete
    end
    add_index :iterations, [:project_id, :iteration_number], :unique => true
  end

  def self.down
    drop_table :iterations
  end
end
