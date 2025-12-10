class CustomMail < ApplicationRecord
  belongs_to :doctor
  belongs_to :patient

  validates :body, presence: true
  after_create_commit { broadcast_notification }

  private

  def broadcast_notification
    ActionCable.server.broadcast("MailChannel", {
      id: id,
      subject: subject,
      body: body,
      sent_at: sent_at
    })
  end
end
