# frozen_string_literal: true

class CreateVenueReservations < ActiveRecord::Migration[7.0]
  def change
    create_table :venue_reservations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      # References
      t.references :venue, null: false, foreign_key: true, type: :uuid
      t.references :venue_contract, null: false, foreign_key: true, type: :uuid
      t.references :client, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid

      # Reservation Details
      t.string :reservation_number, null: false
      t.string :status, default: 'confirmed' # confirmed, in_progress, completed, cancelled

      # Event Details (copied from contract at time of creation)
      t.string :event_type
      t.integer :expected_guests
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false

      # Pricing (from contract)
      t.decimal :total_amount, precision: 10, scale: 2
      t.decimal :deposit_amount, precision: 10, scale: 2
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0
      t.string :payment_status, default: 'pending' # pending, partial, paid

      # Additional info
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :venue_reservations, :reservation_number, unique: true
    add_index :venue_reservations, :status
    add_index :venue_reservations, :start_date
    add_index :venue_reservations, :end_date
    add_index :venue_reservations, [:start_date, :end_date]
  end
end
