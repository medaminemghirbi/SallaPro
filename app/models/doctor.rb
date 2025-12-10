class Doctor < User
  # #scopes
  scope :current, -> { where(is_archived: false) }
  scope :verified, -> { where( is_verified: true) }

  # #Includes
  include Rails.application.routes.url_helpers

  has_one_attached :avatar
  has_one :doctor_usage
  has_many :documents

  geocoded_by :address
  ## Callbacks

  ## Validations
  after_validation :geocode, if: ->(obj) { obj.address.present? and obj.address_changed? }
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  ## Associations
  has_one_attached :avatar
  has_many :blogs, dependent: :destroy
  has_many :consultations, dependent: :destroy
  has_many :patients, through: :consultations
  has_many :phone_numbers, dependent: :destroy
  has_many :custom_mails
  has_many :ratings, through: :consultations

  has_many :doctor_services, dependent: :destroy
  has_many :services, through: :doctor_services

  def patients_with_consultations
    patients
  end

  def user_image_url
    # Get the URL of the associated image
    avatar.attached? ? url_for(avatar) : nil
  end

  def first_number
    phone_numbers.first&.number
  end

  def user_image_url_mobile
    return nil unless avatar.attached?
    image_url = Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
    host = AppConfig.find_by(key: "mobile")&.value || "localhost:3000"
    image_url.gsub("localhost:3000", host)
  end

  def approved_consultations_count
    consultations.approved.count
  end

  def merged_services
    services.map do |service|
      doctor_service = doctor_services.find { |ds| ds.service_id == service.id }
  
      {
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price,
        doctor_service_id: doctor_service&.id
      }
    end
  end
  
end
