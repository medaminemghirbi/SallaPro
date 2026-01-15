# frozen_string_literal: true

class Venue < ApplicationRecord
  # Includes
  include Rails.application.routes.url_helpers

  # Constants
  VENUE_TYPES = {
    'salle' => 'Salle',
    'jardin' => 'Jardin',
    'terrasse' => 'Terrasse',
    'rooftop' => 'Rooftop',
    'piscine' => 'Piscine',
    'cuisine_equipee' => 'Cuisine équipée',
    'parking' => 'Parking',
    'autre' => 'Autre'
  }.freeze

  STATUS_OPTIONS = {
    'available' => 'Disponible',
    'unavailable' => 'Indisponible',
    'maintenance' => 'En maintenance',
    'reserved' => 'Réservée'
  }.freeze

  # Associations
  belongs_to :company
  has_many :venue_contracts, dependent: :destroy
  has_many :venue_reservations, dependent: :destroy
  has_many_attached :images, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :capacity_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :capacity_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[available unavailable maintenance reserved] }
  validates :venue_type, inclusion: { in: %w[salle jardin terrasse rooftop piscine cuisine_equipee parking autre] }

  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :unavailable, -> { where(status: 'unavailable') }
  scope :indoor, -> { where(is_indoor: true) }
  scope :outdoor, -> { where(is_outdoor: true) }
  scope :by_type, ->(type) { where(venue_type: type) if type.present? }
  scope :by_capacity, ->(min, max = nil) {
    if max.present?
      where('capacity_max >= ? AND capacity_min <= ?', min, max)
    else
      where('capacity_max >= ?', min)
    end
  }

  scope :search_by_term, ->(term) {
    return all if term.blank?
    where(
      "LOWER(name) LIKE :term OR LOWER(description) LIKE :term OR LOWER(location) LIKE :term",
      term: "%#{term.downcase}%"
    )
  }

  # Instance methods
  def capacity_range
    "#{capacity_min} - #{capacity_max} personnes"
  end

  def full_name
    "#{name} (#{venue_type_label})"
  end

  def venue_type_label
    {
      'salle' => 'Salle',
      'jardin' => 'Jardin',
      'terrasse' => 'Terrasse',
      'rooftop' => 'Rooftop',
      'piscine' => 'Piscine',
      'cuisine_equipee' => 'Cuisine équipée',
      'parking' => 'Parking',
      'autre' => 'Autre'
    }[venue_type] || venue_type
  end

  def status_label
    {
      'available' => 'Disponible',
      'unavailable' => 'Indisponible',
      'maintenance' => 'En maintenance',
      'reserved' => 'Réservée'
    }[status] || status
  end

  def amenities_list
    amenities || []
  end

  def image_urls
    images.attached? ? images.map { |img| url_for(img) } : []
  end

  def primary_image_url
    images.attached? ? url_for(images.first) : nil
  end
end
