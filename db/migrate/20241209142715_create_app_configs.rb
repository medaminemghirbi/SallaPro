class CreateAppConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :app_configs, id: :uuid do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
