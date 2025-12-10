class Api::V1::NotificationsController < ApplicationController
  def create
    # Check if a similar notification already exists
    notification = Notification.find_or_initialize_by(
      consultation_id: notification_params[:consultation_id], 
      status: notification_params[:status]
    )
    
    # Update the received_at timestamp if it's a new notification or not
    notification.received_at ||= notification_params[:received_at]
  
    if notification.save
      render json: { message: 'Notification saved successfully', notification: notification }, status: :created
    else
      render json: { errors: notification.errors.full_messages }, status: :unprocessable_entity
    end
  end
  

  # GET /notifications
  def index
    notifications = Notification.all.order(created_at: :desc)
    render json: notifications
  end

  private

  def notification_params
    params.require(:notification).permit(:consultation_id, :status, :received_at)
  end
  
end