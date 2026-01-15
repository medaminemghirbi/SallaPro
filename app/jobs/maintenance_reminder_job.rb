# frozen_string_literal: true

class MaintenanceReminderJob
  include Sidekiq::Worker

  def perform
    Rails.logger.info "Starting MaintenanceReminderJob at #{Time.current}"

    # Check materials needing maintenance (7 days before)
    check_upcoming_maintenance

    # Check materials with overdue maintenance
    check_overdue_maintenance

    # Check warranty expiring soon (30 days before)
    check_warranty_expiry

    Rails.logger.info "Completed MaintenanceReminderJob at #{Time.current}"
  end

  private

  def check_upcoming_maintenance
    # Materials with maintenance due in the next 7 days
    Material.includes(:company).needs_maintenance.find_each do |material|
      next if material.next_maintenance_date.nil?
      next if already_notified?(material, 'maintenance_reminder', 7.days)

      days_left = (material.next_maintenance_date - Date.current).to_i

      company_admin = material.company.admin
      next unless company_admin

      Notification.create_maintenance_reminder(
        user: company_admin,
        company: material.company,
        material: material,
        message: "La maintenance de '#{material.name}' est prévue dans #{days_left} jour(s) (#{material.next_maintenance_date.strftime('%d/%m/%Y')})",
        priority: days_left <= 3 ? 'high' : 'normal'
      )

      Rails.logger.info "Created maintenance reminder for material #{material.id}"
    end
  end

  def check_overdue_maintenance
    # Materials with overdue maintenance
    Material.includes(:company).where('next_maintenance_date < ?', Date.current).find_each do |material|
      next if already_notified?(material, 'maintenance_overdue', 1.day)

      days_overdue = (Date.current - material.next_maintenance_date).to_i

      company_admin = material.company.admin
      next unless company_admin

      Notification.create_maintenance_overdue(
        user: company_admin,
        company: material.company,
        material: material,
        message: "La maintenance de '#{material.name}' est en retard de #{days_overdue} jour(s)! Prévue le #{material.next_maintenance_date.strftime('%d/%m/%Y')}"
      )

      Rails.logger.info "Created overdue maintenance notification for material #{material.id}"
    end
  end

  def check_warranty_expiry
    # Materials with warranty expiring in the next 30 days
    Material.includes(:company).warranty_expiring_soon.find_each do |material|
      next if already_notified?(material, 'warranty_expiry', 7.days)

      days_left = (material.warranty_expiry_date - Date.current).to_i

      company_admin = material.company.admin
      next unless company_admin

      Notification.create_warranty_expiry(
        user: company_admin,
        company: material.company,
        material: material,
        message: "La garantie de '#{material.name}' expire dans #{days_left} jour(s) (#{material.warranty_expiry_date.strftime('%d/%m/%Y')})",
        priority: days_left <= 7 ? 'urgent' : 'high'
      )

      Rails.logger.info "Created warranty expiry notification for material #{material.id}"
    end
  end

  def already_notified?(material, notification_type, within_period)
    Notification.where(
      notifiable: material,
      notification_type: notification_type
    ).where('created_at > ?', within_period.ago).exists?
  end
end
