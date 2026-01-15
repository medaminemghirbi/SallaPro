# frozen_string_literal: true

class VenueReservationSerializer < ActiveModel::Serializer
  attributes :id, :reservation_number, :status, :status_label,
             :event_type, :expected_guests,
             :start_date, :end_date, :duration_hours, :duration_days,
             :total_amount, :deposit_amount, :amount_paid, :remaining_amount,
             :payment_status, :payment_status_label, :fully_paid,
             :notes, :metadata,
             :created_at, :updated_at,
             :venue_id, :venue_name, :venue_info,
             :venue_contract_id, :contract_number,
             :client_id, :client_name, :client_info,
             :is_active, :is_upcoming, :is_past

  def status_label
    object.status_label
  end

  def payment_status_label
    object.payment_status_label
  end

  def duration_hours
    object.duration_hours
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
      capacity_max: object.venue.capacity_max
    }
  end

  def contract_number
    object.venue_contract&.contract_number
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
      phone_number: object.client.phone_number
    }
  end

  def is_active
    object.active?
  end

  def is_upcoming
    object.upcoming?
  end

  def is_past
    object.past?
  end
end
