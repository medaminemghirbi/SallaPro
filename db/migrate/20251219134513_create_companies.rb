class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.string :billing_address
      t.uuid :company_type_id, null: false
      t.timestamps
    end
  end
end
