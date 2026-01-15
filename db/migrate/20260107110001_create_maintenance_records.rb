# frozen_string_literal: true

class CreateMaintenanceRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :maintenance_records, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :material, null: false, foreign_key: true, type: :uuid
      t.references :performed_by, foreign_key: { to_table: :users }, type: :uuid
      t.string :maintenance_type, null: false # preventive, corrective, inspection
      t.string :status, default: 'scheduled' # scheduled, in_progress, completed, cancelled
      t.date :scheduled_date, null: false
      t.date :completed_date
      t.text :description
      t.text :notes
      t.decimal :cost, precision: 10, scale: 2
      t.string :service_provider
      t.jsonb :parts_replaced, default: []
      t.integer :duration_hours

      t.timestamps
    end

    add_index :maintenance_records, :maintenance_type
    add_index :maintenance_records, :status
    add_index :maintenance_records, :scheduled_date
  end
end
