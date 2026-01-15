# frozen_string_literal: true

class Department < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :manager, class_name: 'User', optional: true
  has_many :employees, class_name: 'Employee', dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id, message: 'already exists in this company' }
  validates :code, uniqueness: { scope: :company_id, allow_blank: true }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true

  # Callbacks
  before_validation :generate_code, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :with_employees, -> { where('employees_count > 0') }
  scope :search_by_term, ->(term) {
    return all if term.blank?
    where("LOWER(name) LIKE :term OR LOWER(code) LIKE :term OR LOWER(description) LIKE :term", term: "%#{term.downcase}%")
  }

  # Counter cache
  def update_employees_count!
    update_column(:employees_count, employees.count)
  end

  # Instance methods
  def unique_code
    "DEP-#{code || id.to_s[0..7].upcase}"
  end

  def manager_name
    manager ? "#{manager.firstname} #{manager.lastname}" : nil
  end

  private

  def generate_code
    return if code.present?
    
    base_code = name.to_s.parameterize.upcase[0..5]
    counter = 1
    new_code = base_code
    
    while company.departments.where(code: new_code).exists?
      new_code = "#{base_code}#{counter}"
      counter += 1
    end
    
    self.code = new_code
  end
end
