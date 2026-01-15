# frozen_string_literal: true

class MaterialSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :serial_number, :model, :brand, :category,
             :status, :location, :purchase_price, :purchase_date,
             :warranty_expiry_date, :next_maintenance_date, :maintenance_interval_days,
             :metadata, :created_at, :updated_at,
             :image_url, :assigned_to_name, :warranty_status, :maintenance_status,
             :days_until_maintenance, :days_until_warranty_expiry

  def image_url
    object.image_url
  end

  def assigned_to_name
    object.assigned_to_name
  end

  def warranty_status
    object.warranty_status
  end

  def maintenance_status
    object.maintenance_status
  end

  def days_until_maintenance
    object.days_until_maintenance
  end

  def days_until_warranty_expiry
    object.days_until_warranty_expiry
  end
end
