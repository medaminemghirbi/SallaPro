# frozen_string_literal: true

class AddDepartmentAndTeamToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :company, foreign_key: true, type: :uuid
    add_reference :users, :department, foreign_key: true, type: :uuid
    add_reference :users, :team, foreign_key: true, type: :uuid
    add_column :users, :position, :string
    add_column :users, :hire_date, :date
    add_column :users, :employee_id, :string
    add_column :users, :status, :string, default: 'active'
    add_column :users, :contract_type, :string
    add_column :users, :work_schedule, :string
    add_column :users, :salary, :decimal, precision: 10, scale: 2
    add_column :users, :skills, :text, array: true, default: []
    add_column :users, :emergency_contact_name, :string
    add_column :users, :emergency_contact_phone, :string

    add_index :users, :employee_id
    add_index :users, :status
    add_index :users, :position
    add_index :users, :hire_date
  end
end
