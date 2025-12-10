class Maladie < ApplicationRecord
  ##scopes
  scope :current, -> { where(is_archived: false) }
  ##Includes
  include Rails.application.routes.url_helpers

  ## Callbacks

  ## Validations
  validates :maladie_name, presence: true, uniqueness: true

  ## Associations
  has_one_attached :image
  has_many :blogs
  def diseas_image_url
    # Get the URL of the associated image
    image.attached? ? url_for(image) : nil
  end

  def diseas_image_url_mobile
    return nil unless image.attached?
    image_url = Rails.application.routes.url_helpers.rails_blob_url(image, only_path: false)
    host = AppConfig.find_by(key: "mobile")&.value || "localhost:3000"
    image_url.gsub("localhost:3000", host)
  end


end