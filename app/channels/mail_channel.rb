class MailChannel < ApplicationCable::Channel
  def subscribed
    stream_from "MailChannel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
