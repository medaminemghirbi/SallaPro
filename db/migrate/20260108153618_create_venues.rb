class CreateVenues < ActiveRecord::Migration[7.0]
  def change
    create_table :venues, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :venue_type, default: 'salle'
      t.integer :capacity_min, default: 0
      t.integer :capacity_max, default: 0
      t.decimal :surface_area, precision: 10, scale: 2
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.decimal :daily_rate, precision: 10, scale: 2
      t.decimal :weekend_rate, precision: 10, scale: 2
      t.string :location
      t.string :floor
      t.jsonb :amenities, default: []
      t.boolean :is_indoor, default: true
      t.boolean :is_outdoor, default: false
      t.boolean :has_catering, default: false
      t.boolean :has_parking, default: false
      t.integer :parking_capacity, default: 0
      t.boolean :has_sound_system, default: false
      t.boolean :has_lighting, default: false
      t.boolean :has_air_conditioning, default: false
      t.boolean :has_stage, default: false
      t.string :status, default: 'available'
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :venues, :name
    add_index :venues, :venue_type
    add_index :venues, :status
    add_index :venues, :capacity_max
  end
end
