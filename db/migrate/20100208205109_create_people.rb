class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :firstname
      t.string :lastname
      t.string :phone_mobile
      t.string :phone_home
      t.string :fax
      t.string :email
      t.boolean :phone_contact_preferred
      t.boolean :email_contact_preferred
      t.boolean :postal_mail_contact_preferred

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
