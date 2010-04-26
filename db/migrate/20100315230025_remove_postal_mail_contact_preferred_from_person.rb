class RemovePostalMailContactPreferredFromPerson < ActiveRecord::Migration
  def self.up
    remove_column :people, :postal_mail_contact_preferred
  end

  def self.down
    add_column :people, :postal_mail_contact_preferred, :boolean
  end
end
