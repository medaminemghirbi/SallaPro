# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authorize_request
      before_action :set_notification, only: [:show, :mark_as_read, :mark_as_unread, :archive, :destroy]

      # GET /api/v1/notifications
      def index
        @notifications = current_user.notifications
                                     .not_archived
                                     .not_expired
                                     .by_type(params[:notification_type])
                                     .urgent_first

        if params[:status] == 'unread'
          @notifications = @notifications.unread
        end

        if params[:page].present?
          @notifications = @notifications.page(params[:page]).per(params[:per_page] || 20)
          render json: {
            notifications: ActiveModelSerializers::SerializableResource.new(@notifications, each_serializer: NotificationSerializer),
            meta: {
              current_page: @notifications.current_page,
              total_pages: @notifications.total_pages,
              total_count: @notifications.total_count,
              unread_count: current_user.notifications.unread.not_expired.count
            }
          }, status: :ok
        else
          render json: {
            notifications: ActiveModelSerializers::SerializableResource.new(@notifications.limit(50), each_serializer: NotificationSerializer),
            unread_count: current_user.notifications.unread.not_expired.count
          }, status: :ok
        end
      end

      # GET /api/v1/notifications/unread_count
      def unread_count
        count = current_user.notifications.unread.not_expired.count
        render json: { unread_count: count }, status: :ok
      end

      # GET /api/v1/notifications/:id
      def show
        render json: @notification, serializer: NotificationSerializer, status: :ok
      end

      # POST /api/v1/notifications/:id/mark_as_read
      def mark_as_read
        @notification.mark_as_read!
        render json: {
          message: 'Notification marked as read',
          notification: NotificationSerializer.new(@notification)
        }, status: :ok
      end

      # POST /api/v1/notifications/:id/mark_as_unread
      def mark_as_unread
        @notification.mark_as_unread!
        render json: {
          message: 'Notification marked as unread',
          notification: NotificationSerializer.new(@notification)
        }, status: :ok
      end

      # POST /api/v1/notifications/mark_all_as_read
      def mark_all_as_read
        current_user.notifications.unread.update_all(status: 'read', read_at: Time.current)
        render json: { message: 'All notifications marked as read' }, status: :ok
      end

      # POST /api/v1/notifications/:id/archive
      def archive
        @notification.archive!
        render json: { message: 'Notification archived' }, status: :ok
      end

      # DELETE /api/v1/notifications/:id
      def destroy
        if @notification.destroy
          render json: { message: 'Notification deleted' }, status: :ok
        else
          render json: { error: 'Failed to delete notification' }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/notifications/clear_all
      def clear_all
        current_user.notifications.where(status: 'read').destroy_all
        render json: { message: 'Read notifications cleared' }, status: :ok
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end
    end
  end
end
