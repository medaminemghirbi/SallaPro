# frozen_string_literal: true

class Material < ApplicationRecord
  belongs_to :company
  belongs_to :assigned_to, class_name: 'User', optional: true
  has_many :maintenance_records, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_one_attached :image

  # Validations
  validates :name, presence: true

  # Status options
  STATUSES = %w[active inactive in_maintenance retired].freeze
  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  # Scopes
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :active, -> { where(status: 'active') }
  scope :needs_maintenance, -> { where('next_maintenance_date <= ?', Date.current + 7.days) }
  scope :warranty_expiring_soon, -> { where('warranty_expiry_date <= ? AND warranty_expiry_date >= ?', Date.current + 30.days, Date.current) }
  scope :warranty_expired, -> { where('warranty_expiry_date < ?', Date.current) }
  scope :search_by_name, ->(query) { where('name ILIKE ? OR serial_number ILIKE ? OR brand ILIKE ?', "%#{query}%", "%#{query}%", "%#{query}%") if query.present? }
  scope :recent, -> { order(created_at: :desc) }

  include Rails.application.routes.url_helpers

  def image_url
    image.attached? ? url_for(image) : nil
  end

  def assigned_to_name
    assigned_to ? "#{assigned_to.firstname} #{assigned_to.lastname}" : nil
  end

  def warranty_status
    return 'no_warranty' unless warranty_expiry_date
    return 'expired' if warranty_expiry_date < Date.current
    return 'expiring_soon' if warranty_expiry_date <= Date.current + 30.days
    'valid'
  end

  def maintenance_status
    return 'no_schedule' unless next_maintenance_date
    return 'overdue' if next_maintenance_date < Date.current
    return 'due_soon' if next_maintenance_date <= Date.current + 7.days
    'on_schedule'
  end

  def days_until_maintenance
    return nil unless next_maintenance_date
    (next_maintenance_date - Date.current).to_i
  end

  def days_until_warranty_expiry
    return nil unless warranty_expiry_date
    (warranty_expiry_date - Date.current).to_i
  end

  def update_next_maintenance_date!
    return unless maintenance_interval_days.present? && maintenance_interval_days > 0
    
    last_maintenance = maintenance_records.where(status: 'completed').order(completed_date: :desc).first
    base_date = last_maintenance&.completed_date || purchase_date || Date.current
    
    self.next_maintenance_date = base_date + maintenance_interval_days.days
    save!
  end

  def last_maintenance
    maintenance_records.where(status: 'completed').order(completed_date: :desc).first
  end

  def pending_maintenance
    maintenance_records.where(status: ['scheduled', 'in_progress']).order(scheduled_date: :asc)
  end
end
