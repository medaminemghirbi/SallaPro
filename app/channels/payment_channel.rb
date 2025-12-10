class PaymentChannel < ApplicationCable::Channel
  def subscribed
    stream_from "PaymentChannel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
