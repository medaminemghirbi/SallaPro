# frozen_string_literal: true

class VenueContract < ApplicationRecord
  # Includes
  include Rails.application.routes.url_helpers

  # Constants
  STATUS_OPTIONS = {
    'draft' => 'Brouillon',
    'devis' => 'Devis',
    'contract' => 'Contrat',
    'signed' => 'Signé',
    'cancelled' => 'Annulé'
  }.freeze

  PAYMENT_STATUS_OPTIONS = {
    'pending' => 'En attente',
    'partial' => 'Partiel',
    'paid' => 'Payé'
  }.freeze

  EVENT_TYPES = {
    'wedding' => 'Mariage',
    'birthday' => 'Anniversaire',
    'corporate' => 'Événement d\'entreprise',
    'conference' => 'Conférence',
    'seminar' => 'Séminaire',
    'party' => 'Fête',
    'meeting' => 'Réunion',
    'exhibition' => 'Exposition',
    'concert' => 'Concert',
    'other' => 'Autre'
  }.freeze

  # Associations
  belongs_to :venue
  belongs_to :client, class_name: 'User'
  belongs_to :company
  belongs_to :created_by, class_name: 'User'
  has_one :venue_reservation, dependent: :nullify
  has_one_attached :signed_document

  # Validations
  validates :contract_number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :status, inclusion: { in: STATUS_OPTIONS.keys }
  validates :payment_status, inclusion: { in: PAYMENT_STATUS_OPTIONS.keys }, allow_nil: true
  validates :event_type, inclusion: { in: EVENT_TYPES.keys }, allow_nil: true

  # Scopes
  scope :drafts, -> { where(status: 'draft') }
  scope :devis, -> { where(status: 'devis') }
  scope :contracts, -> { where(status: 'contract') }
  scope :signed, -> { where(status: 'signed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :active, -> { where.not(status: 'cancelled') }
  scope :by_venue, ->(venue_id) { where(venue_id: venue_id) if venue_id.present? }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where('event_start_date >= ?', Time.current).order(event_start_date: :asc) }

  scope :search_by_term, ->(term) {
    return all if term.blank?
    joins(:client, :venue)
      .where(
        "LOWER(venue_contracts.contract_number) LIKE :term OR 
         LOWER(venue_contracts.title) LIKE :term OR 
         LOWER(users.firstname) LIKE :term OR 
         LOWER(users.lastname) LIKE :term OR
         LOWER(venues.name) LIKE :term",
        term: "%#{term.downcase}%"
      )
  }

  # Callbacks
  before_validation :generate_contract_number, on: :create
  before_save :calculate_totals

  # Instance methods
  def status_label
    STATUS_OPTIONS[status] || status
  end

  def payment_status_label
    PAYMENT_STATUS_OPTIONS[payment_status] || payment_status
  end

  def event_type_label
    EVENT_TYPES[event_type] || event_type
  end

  def client_name
    client ? "#{client.firstname} #{client.lastname}" : 'N/A'
  end

  def venue_name
    venue&.name || 'N/A'
  end

  def duration_days
    return 0 unless event_start_date && event_end_date
    ((event_end_date - event_start_date) / 1.day).ceil
  end

  def remaining_amount
    (total_amount || 0) - (amount_paid || 0)
  end

  def fully_paid?
    remaining_amount <= 0
  end

  def can_convert_to_devis?
    status == 'draft'
  end

  def can_convert_to_contract?
    status == 'devis'
  end

  def can_sign?
    status == 'contract'
  end

  def convert_to_devis!
    return false unless can_convert_to_devis?
    update(status: 'devis', sent_at: Time.current)
  end

  def convert_to_contract!
    return false unless can_convert_to_contract?
    update(status: 'contract')
  end

  def sign!(signed_pdf = nil)
    return false unless can_sign?

    transaction do
      update!(status: 'signed', signed_at: Time.current)
      
      # Attach signed document if provided
      signed_document.attach(signed_pdf) if signed_pdf.present?
      
      # Create reservation
      create_reservation!
      
      # Store in library
      store_in_library!
    end
    true
  rescue => e
    Rails.logger.error "Failed to sign contract: #{e.message}"
    false
  end

  def signed_document_url
    return nil unless signed_document.attached?
    url_for(signed_document)
  end

  private

  def generate_contract_number
    return if contract_number.present?
    
    prefix = 'CTR'
    year = Time.current.year
    month = Time.current.month.to_s.rjust(2, '0')
    
    last_contract = VenueContract.where('contract_number LIKE ?', "#{prefix}-#{year}#{month}-%")
                                  .order(contract_number: :desc)
                                  .first
    
    if last_contract && last_contract.contract_number.present?
      last_number = last_contract.contract_number.split('-').last.to_i
      new_number = (last_number + 1).to_s.rjust(4, '0')
    else
      new_number = '0001'
    end
    
    self.contract_number = "#{prefix}-#{year}#{month}-#{new_number}"
  end

  def calculate_totals
    return unless base_price.present?

    # Calculate discount
    disc = if discount_percent.present? && discount_percent > 0
             base_price * (discount_percent / 100)
           else
             discount_amount || 0
           end

    subtotal = base_price - disc

    # Calculate tax
    self.tax_amount = subtotal * ((tax_rate || 20) / 100)
    self.total_amount = subtotal + tax_amount
  end

  def create_reservation!
    VenueReservation.create!(
      venue: venue,
      venue_contract: self,
      client: client,
      company: company,
      event_type: event_type,
      expected_guests: expected_guests,
      start_date: event_start_date,
      end_date: event_end_date,
      total_amount: total_amount,
      deposit_amount: deposit_amount,
      amount_paid: amount_paid,
      payment_status: payment_status,
      status: 'confirmed'
    )
  end

  def store_in_library!
    return unless signed_document.attached?

    CompanyDocument.create!(
      company: company,
      uploaded_by: created_by,
      name: "Contrat - #{title} - #{contract_number}",
      description: "Contrat signé pour #{venue_name} - Client: #{client_name}",
      document_type: 'contract',
      category: 'venue_contracts',
      file: signed_document.blob,
      metadata: {
        contract_id: id,
        venue_id: venue_id,
        client_id: client_id,
        signed_at: signed_at
      }
    )
  end
end
