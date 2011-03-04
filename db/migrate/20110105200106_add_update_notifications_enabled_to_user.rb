class AddUpdateNotificationsEnabledToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :update_notifications_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :users, :update_notifications_enabled
  end
end
