class CreateDoctorServices < ActiveRecord::Migration[7.0]
  def change
    create_table :doctor_services, id: :uuid do |t|
      t.uuid :doctor_id, null: false
      t.uuid :service_id, null: false
      t.timestamps
    end
    add_index :doctor_services, [:doctor_id, :service_id], unique: true, name: "index_doctor_services_on_doctor_and_service"
  end
end
