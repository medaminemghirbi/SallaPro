# frozen_string_literal: true

class SupplierSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :address, :city, :country, :postal_code,
             :contact_person, :contact_email, :contact_phone, :website, :tax_id,
             :category, :description, :notes, :payment_terms, :status,
             :latitude, :longitude, :unique_code, :logo_url, :full_address,
             :created_at, :updated_at

  def unique_code
    "SUP#{object.id.to_s[0..7].upcase}"
  end

  def full_address
    [object.address, object.city, object.postal_code, object.country].compact.join(', ')
  end

  def logo_url
    object.logo_url
  end
end
