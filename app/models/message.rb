class Message < ApplicationRecord
  include Rails.application.routes.url_helpers
  scope :current, -> { where(is_archived: false) }
  after_create_commit { broadcast_message }
  belongs_to :sender, class_name: 'User'
  has_many_attached :images, dependent: :destroy

  def message_image_urls
    
    images.map do |image|
      image_url = Rails.application.routes.url_helpers.rails_blob_url(image, only_path: false)
      host = AppConfig.find_by(key: "mobile")&.value || "localhost:3000"
      image_url = image_url.gsub("localhost:3000", host)  
      {
        id: image.id,
        url: image_url
      }
    end
  end
  private

  def broadcast_message
    ActionCable.server.broadcast('MessagesChannel', {
      id: self.id,
      body: self.body,
      sender_id: self.sender_id,
      sender: {
        user_image_url: self.sender.user_image_url_mobile,
        firstname: self.sender.firstname,
        lastname: self.sender.lastname
      },
      created_at: self.created_at.strftime('%Y-%m-%d %H:%M:%S'),
      images: message_image_urls
    })
  end
end