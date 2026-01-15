# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  # Validations
  validates :title, presence: true
  validates :notification_type, presence: true

  # Notification types
  NOTIFICATION_TYPES = %w[maintenance_reminder warranty_expiry maintenance_overdue system info success warning error].freeze
  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  # Priority levels
  PRIORITIES = %w[low normal high urgent].freeze
  validates :priority, inclusion: { in: PRIORITIES }

  # Status options
  STATUSES = %w[unread read archived].freeze
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :unread, -> { where(status: 'unread') }
  scope :read, -> { where(status: 'read') }
  scope :not_archived, -> { where.not(status: 'archived') }
  scope :by_type, ->(type) { where(notification_type: type) if type.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :urgent_first, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 ELSE 4 END"), created_at: :desc) }

  def mark_as_read!
    update!(status: 'read', read_at: Time.current)
  end

  def mark_as_unread!
    update!(status: 'unread', read_at: nil)
  end

  def archive!
    update!(status: 'archived')
  end

  def icon_class
    case notification_type
    when 'maintenance_reminder' then 'bi-tools'
    when 'warranty_expiry' then 'bi-shield-exclamation'
    when 'maintenance_overdue' then 'bi-exclamation-triangle'
    when 'success' then 'bi-check-circle'
    when 'warning' then 'bi-exclamation-circle'
    when 'error' then 'bi-x-circle'
    when 'info' then 'bi-info-circle'
    else 'bi-bell'
    end
  end

  def priority_color
    case priority
    when 'urgent' then 'danger'
    when 'high' then 'warning'
    when 'normal' then 'primary'
    else 'secondary'
    end
  end

  # Class methods for creating notifications
  class << self
    def create_maintenance_reminder(user:, company:, material:, message:, priority: 'normal')
      create!(
        user: user,
        company: company,
        notifiable: material,
        title: "Rappel de maintenance: #{material.name}",
        message: message,
        notification_type: 'maintenance_reminder',
        priority: priority,
        action_url: "/admin/materials/#{material.id}"
      )
    end

    def create_warranty_expiry(user:, company:, material:, message:, priority: 'high')
      create!(
        user: user,
        company: company,
        notifiable: material,
        title: "Expiration de garantie: #{material.name}",
        message: message,
        notification_type: 'warranty_expiry',
        priority: priority,
        action_url: "/admin/materials/#{material.id}"
      )
    end

    def create_maintenance_overdue(user:, company:, material:, message:)
      create!(
        user: user,
        company: company,
        notifiable: material,
        title: "Maintenance en retard: #{material.name}",
        message: message,
        notification_type: 'maintenance_overdue',
        priority: 'urgent',
        action_url: "/admin/materials/#{material.id}"
      )
    end
  end
end
