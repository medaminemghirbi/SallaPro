class ConsultationReport < ApplicationRecord
    include Rails.application.routes.url_helpers

    belongs_to :consultation
  
    validates :diagnosis, :procedures, :prescription, :doctor_notes, presence: true
    has_many_attached :images
    def image_urls
        images.map { |image| url_for(image) }
    end
end