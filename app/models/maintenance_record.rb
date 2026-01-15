# frozen_string_literal: true

class MaintenanceRecord < ApplicationRecord
  belongs_to :material
  belongs_to :performed_by, class_name: 'User', optional: true
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Validations
  validates :maintenance_type, presence: true
  validates :scheduled_date, presence: true

  # Maintenance types
  MAINTENANCE_TYPES = %w[preventive corrective inspection calibration].freeze
  validates :maintenance_type, inclusion: { in: MAINTENANCE_TYPES }

  # Status options
  STATUSES = %w[scheduled in_progress completed cancelled].freeze
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :by_material, ->(material_id) { where(material_id: material_id) }
  scope :by_type, ->(type) { where(maintenance_type: type) if type.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :upcoming, -> { where('scheduled_date >= ?', Date.current).order(scheduled_date: :asc) }
  scope :overdue, -> { where('scheduled_date < ? AND status IN (?)', Date.current, ['scheduled', 'in_progress']) }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_save :update_material_next_maintenance, if: -> { saved_change_to_status? && status == 'completed' }

  def performed_by_name
    performed_by ? "#{performed_by.firstname} #{performed_by.lastname}" : nil
  end

  def material_name
    material&.name
  end

  def is_overdue?
    scheduled_date < Date.current && status.in?(['scheduled', 'in_progress'])
  end

  def days_until_due
    (scheduled_date - Date.current).to_i
  end

  private

  def update_material_next_maintenance
    material.update_next_maintenance_date! if material.present?
  end
end
