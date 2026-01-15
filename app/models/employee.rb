class Employee < User
  # Scopes
  scope :current, -> { where(is_archived: false) }
  scope :verified, -> { where(is_verified: true) }
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :on_leave, -> { where(status: 'on_leave') }
  scope :terminated, -> { where(status: 'terminated') }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_department, ->(department_id) { where(department_id: department_id) if department_id.present? }
  scope :by_position, ->(position) { where(position: position) if position.present? }
  scope :recent, -> { where('created_at >= ?', 30.days.ago) }
  scope :hired_between, ->(start_date, end_date) { where(hire_date: start_date..end_date) }
  
  scope :search_by_term, ->(term) {
    return all if term.blank?
    where(
      "LOWER(firstname) LIKE :term OR LOWER(lastname) LIKE :term OR LOWER(email) LIKE :term OR LOWER(position) LIKE :term OR LOWER(employee_id) LIKE :term",
      term: "%#{term.downcase}%"
    )
  }

  # Includes
  include Rails.application.routes.url_helpers

  # Attachments
  has_one_attached :avatar

  # Geocoding
  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  # Associations
  belongs_to :company, optional: true
  belongs_to :department, optional: true, counter_cache: :employees_count
  # has_many :custom_mails
  # has_many :documents

  # Validations
  validates :status, inclusion: { in: %w[active inactive on_leave terminated] }, allow_blank: true
  validates :contract_type, inclusion: { in: %w[full_time part_time contract intern freelance] }, allow_blank: true
  validates :employee_id, uniqueness: { scope: :company_id, allow_blank: true }

  # Callbacks
  before_validation :set_default_status, on: :create
  before_create :generate_employee_id

  # Instance methods
  def full_name
    "#{firstname} #{lastname}".strip
  end

  def initials
    "#{firstname&.first}#{lastname&.first}".upcase
  end

  def years_of_service
    return nil unless hire_date
    ((Date.current - hire_date) / 365.25).floor
  end

  def tenure
    return nil unless hire_date
    years = years_of_service
    return "#{years} year#{'s' if years != 1}" if years > 0
    
    months = ((Date.current - hire_date) / 30.44).floor
    "#{months} month#{'s' if months != 1}"
  end

  def unique_code
    employee_id || "EMP-#{id.to_s[0..7].upcase}"
  end

  def department_name
    department&.name
  end

  def manager_name
    department&.manager_name
  end

  def user_image_url
    avatar.attached? ? url_for(avatar) : nil
  end

  def first_number
    phone_numbers.first&.number
  end

  def user_image_url_mobile
    return nil unless avatar.attached?
    image_url = Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
    host = AppConfig.find_by(key: "mobile")&.value || "localhost:3000"
    image_url.gsub("localhost:3000", host)
  end


  private

  def set_default_status
    self.status ||= 'active'
  end

  def generate_employee_id
    return if employee_id.present? || company_id.blank?
    
    prefix = "EMP"
    year = Date.current.year.to_s[-2..]
    sequence = Employee.where(company_id: company_id).count + 1
    self.employee_id = "#{prefix}-#{year}-#{sequence.to_s.rjust(4, '0')}"
  end
end
