# frozen_string_literal: true

class MaintenanceRecordSerializer < ActiveModel::Serializer
  attributes :id, :maintenance_type, :status, :scheduled_date, :completed_date,
             :description, :notes, :cost, :service_provider, :parts_replaced,
             :duration_hours, :created_at, :updated_at,
             :performed_by_name, :material_name, :is_overdue, :days_until_due,
             :material_id

  def performed_by_name
    object.performed_by_name
  end

  def material_name
    object.material_name
  end

  def is_overdue
    object.is_overdue?
  end

  def days_until_due
    object.days_until_due
  end
end
