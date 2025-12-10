class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages, id: :uuid  do |t|
      t.text :body
      t.boolean  :is_archived, :default => false

      t.timestamps
    end
  end
end
