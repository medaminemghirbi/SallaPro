# frozen_string_literal: true

class Supplier < ApplicationRecord
  # Includes
  include Rails.application.routes.url_helpers

  # Associations
  belongs_to :company
  has_one_attached :logo, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :status, inclusion: { in: %w[active inactive suspended] }

  # Geocoding
  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  # Callbacks
  before_validation :set_default_status, on: :create

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  scope :search_by_term, ->(term) {
    return all if term.blank?
    
    where(
      "LOWER(name) LIKE :term OR LOWER(email) LIKE :term OR LOWER(contact_person) LIKE :term OR LOWER(address) LIKE :term OR LOWER(city) LIKE :term",
      term: "%#{term.downcase}%"
    )
  }

  # Instance methods
  def full_address
    [address, city, postal_code, country].compact.join(', ')
  end

  def unique_code
    "SUP#{id.to_s[0..7].upcase}"
  end

  def logo_url
    logo.attached? ? url_for(logo) : nil
  end

  private

  def set_default_status
    self.status ||= 'active'
  end
end
