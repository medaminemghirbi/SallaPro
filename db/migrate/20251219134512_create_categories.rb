class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name
      t.string :key
      t.string :resource_type
      t.text :description
      t.timestamps
    end
  end
end
