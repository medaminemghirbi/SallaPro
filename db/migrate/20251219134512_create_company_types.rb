class CreateCompanyTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :company_types, id: :uuid do |t|
      t.string :name
      t.string :key
      t.text :description
      t.timestamps
    end
  end
end
