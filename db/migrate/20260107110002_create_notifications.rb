# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :company, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.text :message
      t.string :notification_type, null: false # maintenance_reminder, warranty_expiry, system, info
      t.string :priority, default: 'normal' # low, normal, high, urgent
      t.string :status, default: 'unread' # unread, read, archived
      t.string :action_url
      t.string :icon
      t.references :notifiable, polymorphic: true, type: :uuid
      t.datetime :read_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, :status
    add_index :notifications, :priority
    add_index :notifications, [:user_id, :status]
  end
end
