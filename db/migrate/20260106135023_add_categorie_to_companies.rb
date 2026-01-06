class AddCategorieToCompanies < ActiveRecord::Migration[7.0]
  def change
    add_reference :companies, :categorie, null: true, foreign_key: true, type: :uuid
  end
end
