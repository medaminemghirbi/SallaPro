class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      ## Database authenticatable
      t.string :email, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## User Information
      t.string :firstname
      t.string :lastname
      t.string :address
      t.date :birthday
      t.integer :gender, default: 0
      t.integer :civil_status, default: 0
      t.boolean :is_archived, default: false
      t.integer :order, default: 1
      t.string :type # STI

      ## Doctor-specific fields
      t.string :location
      t.string :specialization
      t.float :latitude
      t.float :longitude
      t.string :description
      t.string :code_doc
      t.string :website
      t.string :twitter
      t.string :youtube
      t.string :facebook
      t.string :linkedin
      t.string :phone_number

      ## Patient-specific fields
      t.string :medical_history
      t.integer :plan, default: 0
      t.integer :custom_limit, default: 0
      t.integer :radius, default: 5

      ## User Settings
      t.boolean :is_emailable, default: false
      t.boolean :is_notifiable, default: false
      t.boolean :is_smsable, default: false
      t.boolean :working_saturday, default: false
      t.boolean :working_on_line, default: false
      t.integer :amount
      t.integer :plateform

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true

  end
end
