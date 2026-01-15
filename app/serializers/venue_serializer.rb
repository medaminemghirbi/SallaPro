# frozen_string_literal: true

class VenueSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :description, :venue_type, :venue_type_label,
             :capacity_min, :capacity_max, :capacity_range,
             :surface_area, :hourly_rate, :daily_rate, :weekend_rate,
             :location, :floor, :amenities, :amenities_list,
             :is_indoor, :is_outdoor,
             :has_catering, :has_parking, :parking_capacity,
             :has_sound_system, :has_lighting, :has_air_conditioning, :has_stage,
             :status, :status_label,
             :created_at, :updated_at,
             :image_urls, :primary_image_url, :features

  belongs_to :company, serializer: CompanyMinimalSerializer

  def venue_type_label
    object.venue_type_label
  end

  def capacity_range
    object.capacity_range
  end

  def status_label
    object.status_label
  end

  def amenities_list
    object.amenities_list
  end

  def image_urls
    return [] unless object.images.attached?

    object.images.map do |image|
      rails_blob_url(image, only_path: false)
    end
  rescue StandardError
    []
  end

  def primary_image_url
    return nil unless object.images.attached?

    rails_blob_url(object.images.first, only_path: false)
  rescue StandardError
    nil
  end

  # Additional computed field for all features/amenities
  def features
    features_list = []

    features_list << { key: 'is_indoor', label: 'Intérieur', value: object.is_indoor }
    features_list << { key: 'is_outdoor', label: 'Extérieur', value: object.is_outdoor }
    features_list << { key: 'has_catering', label: 'Service traiteur', value: object.has_catering }
    features_list << { key: 'has_parking', label: 'Parking', value: object.has_parking, capacity: object.parking_capacity }
    features_list << { key: 'has_sound_system', label: 'Sonorisation', value: object.has_sound_system }
    features_list << { key: 'has_lighting', label: 'Éclairage', value: object.has_lighting }
    features_list << { key: 'has_air_conditioning', label: 'Climatisation', value: object.has_air_conditioning }
    features_list << { key: 'has_stage', label: 'Scène', value: object.has_stage }

    features_list
  end
end
