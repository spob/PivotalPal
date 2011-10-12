class RenameIntegrationDurationDays < ActiveRecord::Migration
  def self.up
    rename_column :projects, :iteration_duration_days, :iteration_duration_weeks
  end

  def self.down
    rename_column :projects, :iteration_duration_weeks, :iteration_duration_days
  end
end
