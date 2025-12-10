class ConsultationChannel < ApplicationCable::Channel
  def subscribed
    user_id = params[:user_id]
    
    # Ensure the user_id is valid and then stream from the specific user's channel
    if user_id.present?
      stream_from "ConsultationChannel_#{user_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup when unsubscribed
  end
end
