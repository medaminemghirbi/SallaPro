class CreateHolidays < ActiveRecord::Migration[7.0]
  def change
    create_table :holidays do |t|
      t.string   :holiday_name,          null: false
      t.date     :holiday_date,          null: false
      t.boolean :is_archived, :default => false
      t.timestamps
    end
  end
end
