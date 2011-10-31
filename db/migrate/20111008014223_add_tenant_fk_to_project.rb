class AddTenantFkToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :pivotal_identifier, :integer, :null => false
  end

  def self.down
    remove_column :projects, :pivotal_identifier
  end
end
