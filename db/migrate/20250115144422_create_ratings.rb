class CreateRatings < ActiveRecord::Migration[7.0]
  def change
    create_table :ratings, id: :uuid do |t|
      t.uuid :consultation_id, null: false
      t.integer :rating_value
      t.string :comment
      t.timestamps
    end
  end
end
