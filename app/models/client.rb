class Client < User
  # Includes
  include Rails.application.routes.url_helpers

  # Associations
  has_one :company, foreign_key: 'user_id', dependent: :destroy

  # Geocoding
  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  # Validations
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  validates :status, inclusion: { in: %w[active inactive blocked] }, allow_nil: true

  # Callbacks
  before_validation :set_default_status, on: :create

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :blocked, -> { where(status: 'blocked') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_country, ->(country) { where(country: country) if country.present? }

  scope :search_by_term, ->(term) {
    return all if term.blank?
    
    where(
      "LOWER(firstname) LIKE :term OR LOWER(lastname) LIKE :term OR LOWER(email) LIKE :term OR LOWER(phone_number) LIKE :term OR LOWER(address) LIKE :term",
      term: "%#{term.downcase}%"
    )
  }

  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Instance methods
  def full_name
    "#{firstname} #{lastname}"
  end

  def initials
    "#{firstname&.first&.upcase}#{lastname&.first&.upcase}"
  end

  def age
    return nil unless birthday.present?
    
    now = Time.current.to_date
    age = now.year - birthday.year
    age -= 1 if now < birthday + age.years
    age
  end

  def member_since
    created_at&.strftime('%B %Y')
  end

  def last_activity
    updated_at
  end

  private

  def set_default_status
    self.status ||= 'active'
  end
end
