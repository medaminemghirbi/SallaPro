# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false
      t.string :code
      t.text :description
      t.string :color, default: '#10B981'
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :department, foreign_key: true, type: :uuid
      t.references :leader, foreign_key: { to_table: :users }, type: :uuid
      t.boolean :active, default: true
      t.integer :members_count, default: 0

      t.timestamps
    end

    add_index :teams, [:company_id, :name], unique: true
    add_index :teams, [:department_id, :name]
    add_index :teams, :code
    add_index :teams, :active
  end
end
