class ModifyProjectIndex < ActiveRecord::Migration
  def self.up
    add_index :projects, [:tenant_id, :pivotal_identifier], :unique => true
  end

  def self.down
    add_index :projects, [:tenant_id, :name], :unique => true
    remove_index :projects, [:tenant_id, :pivotal_identifier]
  end
end
