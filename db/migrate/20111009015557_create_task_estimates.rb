class CreateTaskEstimates < ActiveRecord::Migration
  def self.up
    create_table :task_estimates do |t|
      t.date :as_of, :null => false
      t.float :total_hours, :null => false
      t.float :remaining_hours, :null => false
      t.float :points_delivered
      t.float :velocity
      t.string :status, :limit => 20
      t.float :remaining_qa_hours
      t.timestamps
    end

    change_table :task_estimates do |t|
      t.references :iteration, :null => false
      t.foreign_key :iterations, :dependent => :delete
      t.references :task
      t.foreign_key :tasks, :dependent => :delete
    end

    add_index :task_estimates, [:iteration_id, :as_of]
    add_index :task_estimates, [:iteration_id, :task_id, :as_of], :unique => true
    add_index :task_estimates, [:task_id, :as_of]
  end

  def self.down
    drop_table :task_estimates
  end
end
