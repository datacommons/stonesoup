class AddImportNoticeTrackingToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :import_notice_sent_at, :datetime
    add_column :organizations, :email_response_token, :string
    add_column :organizations, :responded_at, :datetime
    add_column :organizations, :response, :string
    add_index :organizations, :email_response_token
  end

  def self.down
    remove_index :organizations, :email_response_token
    remove_column :organizations, :import_notice_sent_at
    remove_column :organizations, :email_response_token
    remove_column :organizations, :responded_at
    remove_column :organizations, :response
  end
end
