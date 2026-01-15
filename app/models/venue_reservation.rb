# frozen_string_literal: true

class VenueReservation < ApplicationRecord
  # Includes
  include Rails.application.routes.url_helpers

  # Constants
  STATUS_OPTIONS = {
    'confirmed' => 'Confirmée',
    'in_progress' => 'En cours',
    'completed' => 'Terminée',
    'cancelled' => 'Annulée'
  }.freeze

  PAYMENT_STATUS_OPTIONS = {
    'pending' => 'En attente',
    'partial' => 'Partiel',
    'paid' => 'Payé'
  }.freeze

  # Associations
  belongs_to :venue
  belongs_to :venue_contract
  belongs_to :client, class_name: 'User'
  belongs_to :company

  # Validations
  validates :reservation_number, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, inclusion: { in: STATUS_OPTIONS.keys }
  validates :payment_status, inclusion: { in: PAYMENT_STATUS_OPTIONS.keys }, allow_nil: true
  validate :end_date_after_start_date
  validate :no_overlapping_reservations, on: :create

  # Scopes
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :active, -> { where.not(status: 'cancelled') }
  scope :by_venue, ->(venue_id) { where(venue_id: venue_id) if venue_id.present? }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :upcoming, -> { where('start_date >= ?', Time.current).order(start_date: :asc) }
  scope :past, -> { where('end_date < ?', Time.current).order(end_date: :desc) }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  scope :in_date_range, ->(start_date, end_date) {
    where('start_date <= ? AND end_date >= ?', end_date, start_date)
  }

  scope :search_by_term, ->(term) {
    return all if term.blank?
    joins(:client, :venue)
      .where(
        "LOWER(venue_reservations.reservation_number) LIKE :term OR 
         LOWER(users.firstname) LIKE :term OR 
         LOWER(users.lastname) LIKE :term OR
         LOWER(venues.name) LIKE :term",
        term: "%#{term.downcase}%"
      )
  }

  # Callbacks
  before_validation :generate_reservation_number, on: :create
  after_save :update_venue_status
  after_destroy :reset_venue_status

  # Instance methods
  def status_label
    STATUS_OPTIONS[status] || status
  end

  def payment_status_label
    PAYMENT_STATUS_OPTIONS[payment_status] || payment_status
  end

  def client_name
    client ? "#{client.firstname} #{client.lastname}" : 'N/A'
  end

  def venue_name
    venue&.name || 'N/A'
  end

  def duration_hours
    return 0 unless start_date && end_date
    ((end_date - start_date) / 1.hour).round(1)
  end

  def duration_days
    return 0 unless start_date && end_date
    ((end_date - start_date) / 1.day).ceil
  end

  def remaining_amount
    (total_amount || 0) - (amount_paid || 0)
  end

  def fully_paid?
    remaining_amount <= 0
  end

  def active?
    start_date <= Time.current && end_date >= Time.current
  end

  def upcoming?
    start_date > Time.current
  end

  def past?
    end_date < Time.current
  end

  def cancel!
    update(status: 'cancelled')
    reset_venue_status
  end

  def complete!
    update(status: 'completed')
    reset_venue_status
  end

  private

  def generate_reservation_number
    return if reservation_number.present?
    
    prefix = 'RES'
    year = Time.current.year
    month = Time.current.month.to_s.rjust(2, '0')
    
    last_reservation = VenueReservation.where('reservation_number LIKE ?', "#{prefix}-#{year}#{month}-%")
                                        .order(reservation_number: :desc)
                                        .first
    
    if last_reservation && last_reservation.reservation_number.present?
      last_number = last_reservation.reservation_number.split('-').last.to_i
      new_number = (last_number + 1).to_s.rjust(4, '0')
    else
      new_number = '0001'
    end
    
    self.reservation_number = "#{prefix}-#{year}#{month}-#{new_number}"
  end

  def end_date_after_start_date
    return unless start_date && end_date
    if end_date <= start_date
      errors.add(:end_date, "doit être après la date de début")
    end
  end

  def no_overlapping_reservations
    return unless venue && start_date && end_date

    overlapping = VenueReservation.active
                                   .by_venue(venue_id)
                                   .in_date_range(start_date, end_date)
                                   .where.not(id: id)
    
    if overlapping.exists?
      errors.add(:base, "La salle est déjà réservée pour cette période")
    end
  end

  def update_venue_status
    return unless saved_change_to_status? || saved_change_to_start_date? || saved_change_to_end_date?
    
    if active? && status == 'confirmed'
      venue.update(status: 'reserved')
    end
  end

  def reset_venue_status
    # Check if there are other active reservations
    other_active = VenueReservation.active
                                    .by_venue(venue_id)
                                    .current
                                    .where.not(id: id)
                                    .exists?
    
    unless other_active
      venue.update(status: 'available')
    end
  end
end
