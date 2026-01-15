# frozen_string_literal: true

class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :title, :message, :notification_type, :priority, :status,
             :action_url, :icon, :read_at, :expires_at, :created_at, :updated_at,
             :icon_class, :priority_color, :notifiable_type, :notifiable_id

  def icon_class
    object.icon_class
  end

  def priority_color
    object.priority_color
  end
end
