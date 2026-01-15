# frozen_string_literal: true

class CreateVenueContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :venue_contracts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      # References
      t.references :venue, null: false, foreign_key: true, type: :uuid
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid

      # Contract Details
      t.string :contract_number, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'draft' # draft, devis, contract, signed, cancelled

      # Event Details
      t.string :event_type
      t.integer :expected_guests
      t.datetime :event_start_date
      t.datetime :event_end_date

      # Pricing
      t.decimal :base_price, precision: 10, scale: 2
      t.decimal :discount_percent, precision: 5, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :tax_rate, precision: 5, scale: 2, default: 20
      t.decimal :tax_amount, precision: 10, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2
      t.decimal :deposit_amount, precision: 10, scale: 2
      t.boolean :deposit_paid, default: false
      t.datetime :deposit_paid_at

      # Payment
      t.string :payment_method
      t.string :payment_status, default: 'pending' # pending, partial, paid
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0

      # Dates
      t.date :valid_until
      t.datetime :sent_at
      t.datetime :signed_at

      # Options & Services
      t.jsonb :selected_options, default: []
      t.jsonb :additional_services, default: []
      t.text :special_requests
      t.text :terms_and_conditions
      t.text :internal_notes

      t.timestamps
    end

    add_index :venue_contracts, :contract_number, unique: true
    add_index :venue_contracts, :status
    add_index :venue_contracts, :event_start_date
    add_index :venue_contracts, :created_at
  end
end
