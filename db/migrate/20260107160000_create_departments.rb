# frozen_string_literal: true

class CreateDepartments < ActiveRecord::Migration[7.0]
  def change
    create_table :departments, id: :uuid do |t|
      t.string :name, null: false
      t.string :code
      t.text :description
      t.string :color, default: '#3B82F6'
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :manager, foreign_key: { to_table: :users }, type: :uuid
      t.boolean :active, default: true
      t.integer :employees_count, default: 0

      t.timestamps
    end

    add_index :departments, [:company_id, :name], unique: true
    add_index :departments, :code
    add_index :departments, :active
  end
end
