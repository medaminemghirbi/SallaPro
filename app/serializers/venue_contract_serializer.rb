# frozen_string_literal: true

class VenueContractSerializer < ActiveModel::Serializer
  attributes :id, :contract_number, :title, :description, :status, :status_label,
             :event_type, :event_type_label, :expected_guests,
             :event_start_date, :event_end_date, :duration_days,
             :base_price, :discount_percent, :discount_amount,
             :tax_rate, :tax_amount, :total_amount,
             :deposit_amount, :deposit_paid, :deposit_paid_at,
             :payment_method, :payment_status, :payment_status_label,
             :amount_paid, :remaining_amount, :fully_paid,
             :valid_until, :sent_at, :signed_at,
             :selected_options, :additional_services, :special_requests,
             :terms_and_conditions, :internal_notes,
             :created_at, :updated_at,
             :client_id, :client_name, :client_info,
             :venue_id, :venue_name, :venue_info,
             :created_by_id, :created_by_name,
             :can_convert_to_devis, :can_convert_to_contract, :can_sign,
             :signed_document_url, :has_reservation

  def status_label
    object.status_label
  end

  def event_type_label
    object.event_type_label
  end

  def payment_status_label
    object.payment_status_label
  end

  def duration_days
    object.duration_days
  end

  def remaining_amount
    object.remaining_amount
  end

  def fully_paid
    object.fully_paid?
  end

  def client_name
    object.client_name
  end

  def client_info
    return nil unless object.client
    {
      id: object.client.id,
      firstname: object.client.firstname,
      lastname: object.client.lastname,
      email: object.client.email,
      phone_number: object.client.phone_number,
      address: object.client.address
    }
  end

  def venue_name
    object.venue_name
  end

  def venue_info
    return nil unless object.venue
    {
      id: object.venue.id,
      name: object.venue.name,
      venue_type: object.venue.venue_type,
      location: object.venue.location,
      capacity_max: object.venue.capacity_max,
      hourly_rate: object.venue.hourly_rate,
      daily_rate: object.venue.daily_rate
    }
  end

  def created_by_name
    return nil unless object.created_by
    "#{object.created_by.firstname} #{object.created_by.lastname}"
  end

  def can_convert_to_devis
    object.can_convert_to_devis?
  end

  def can_convert_to_contract
    object.can_convert_to_contract?
  end

  def can_sign
    object.can_sign?
  end

  def signed_document_url
    object.signed_document_url
  end

  def has_reservation
    object.venue_reservation.present?
  end
end
