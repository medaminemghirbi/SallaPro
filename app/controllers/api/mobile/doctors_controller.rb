class Api::Mobile::DoctorsController < ApplicationController
  #before_action :authorize_request

  def nearest
    location = params[:location]
    radius = params[:radius] || 20

    coordinates = Geocoder.coordinates(location)

    if coordinates.nil?
      # Example fallback locations
      fallback_locations = ["#{location} city", "near #{location}"]
      coordinates = fallback_locations.map { |loc| Geocoder.coordinates(loc) }.compact.first
    end

    if coordinates
      @doctors = Doctor.near(coordinates, radius, units: :km)
      render json: @doctors, methods: [:user_image_url_mobile]
    else
      render json: {error: "Location not found"}, status: :unprocessable_entity
    end
  end
def doctor_details
  @doctor = Doctor.includes(:services, :doctor_services, :phone_numbers, :ratings).find_by(id: params[:id])

  if @doctor
    render json: @doctor.as_json(
      methods: [:user_image_url_mobile, :merged_services],
      include: {
        phone_numbers: { only: [:id, :number, :phone_type, :created_at] },  # adapte les attributs que tu veux
        services: { only: [:id, :name] },
        doctor_services: { only: [:id, :service_id, :doctor_id] },
        #ratings: { only: [:id, :rating_value, :comment ]}
        ratings: {
            only: [:id, :comment, :rating_value],
            include: {
              consultation: {
                include: {
                  patient: {
                    only: [:firstname, :lastname],
                    methods: [:user_image_url_mobile]
                  }
                }
              }
            }
          },
      }
    )
  else
    render json: { error: "Doctor not found" }, status: :not_found
  end
end


  def get_selected_doctor
    @doctor = Doctor.find(params[:id])
    render json: @doctor, methods: [:user_image_url_mobile]
  end
end