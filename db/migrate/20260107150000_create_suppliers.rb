# frozen_string_literal: true

class CreateSuppliers < ActiveRecord::Migration[7.0]
  def change
    create_table :suppliers, id: :uuid do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone_number
      t.string :address
      t.string :city
      t.string :country
      t.string :postal_code
      t.string :contact_person
      t.string :contact_email
      t.string :contact_phone
      t.string :website
      t.string :tax_id
      t.string :category
      t.text :description
      t.text :notes
      t.string :payment_terms
      t.string :status, default: 'active'
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.references :company, type: :uuid, foreign_key: true, null: false

      t.timestamps
    end

    add_index :suppliers, :name
    add_index :suppliers, :email
    add_index :suppliers, :status
    add_index :suppliers, :category
  end
end
