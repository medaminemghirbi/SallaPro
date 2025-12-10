class AddConfirmationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirmation_code, :string
    add_column :users, :confirmation_code_generated_at, :datetime
  end
end
