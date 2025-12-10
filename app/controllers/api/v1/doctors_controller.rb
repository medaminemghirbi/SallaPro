require "yaml"

class Api::V1::DoctorsController < ApplicationController
  before_action :authorize_request, except: [:unique_locations, :rate_doctor, :index_home, :search_doctors, :fetch_doctor_data]
  def getDoctorStatistique
    @doctor = Doctor.find_by(id: params[:doctor_id])

    if @doctor.present?
      # Fetch statistics
      @consultations = Consultation.current.where(doctor_id: params[:doctor_id]).count
      @blogs = Blog.current.where(doctor_id: params[:doctor_id]).count

      # Render the doctor with additional data
      render json: {
        doctor: @doctor,
        consultation: @consultations,
        blogs: @blogs
      }
    else
      render json: {error: "Doctor not found"}, status: :not_found
    end
  end




  def index
    doctors = Doctor.current.order(:order)
  
    render json: doctors.map { |doctor|
      doctor.as_json(methods: [:user_image_url, :verification_pdf_url]).merge(confirmed_at: doctor.confirmed_at)
    }
  end
  

  def index_home
    doctors = Doctor.current.includes(consultations: :rating).order(:order)

    render json: doctors.as_json(
      methods: [:user_image_url],
      include: {
        ratings: {only: [:id, :comment, :rating_value]}
      }
    ).map { |doctor|
      ratings = doctor["ratings"].map { |r| Rating.find(r["id"]) }
      doctor.merge(
        rating_count: ratings.size,
        total_rating_value: ratings.sum(&:rating_value)
      )
    }
  end

  def show
    @doctor = Doctor.find(params[:id])
    render json: @doctor, methods: [:user_image_url, :approved_consultations_count], include: :phone_numbers
  end

  def destroy
    @user = User.find(params[:id])
    @user.update(is_archived: true)
  end

  def unique_locations
    # Load the YAML file and access the 'gouvernements' key
    gouvernements = YAML.load_file(Rails.root.join("app", "services", "locations.yml"))["gouvernements"]

    # Render the array directly as JSON
    if gouvernements
      render json: gouvernements, status: :ok
    else
      render json: {errors: "No data found"}, status: :not_found
    end
  end

  def get_doctors_by_locations
    @doctors = Doctor.where(location: params[:location])
    render json: @doctors
  end


  def activate_compte
    @user = User.find(params[:id])

    if @user.update(confirmed_at: Time.now, confirmation_token: nil, is_verified: true)
      render json: {message: "Account successfully activated."}, status: :ok
    else
      render json: {errors: @user.errors.full_messages}, status: :unprocessable_entity
    end
  end


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
      @doctors = Doctor.verified.near(coordinates, radius, units: :km)
      render json: @doctors.as_json(
        methods: [:user_image_url],
        include: {
          ratings: {only: [:id, :comment, :rating_value]}
        }
      ).map { |doctor|
        ratings = doctor["ratings"].map { |r| Rating.find(r["id"]) }
        doctor.merge(
          rating_count: ratings.size,
          total_rating_value: ratings.sum(&:rating_value)
        )
      }

    else
      render json: {error: "Location not found"}, status: :unprocessable_entity
    end
  end

  def updatedoctorimage
    @user = User.find(params[:id])
    if @user.update(paramsimagefreelancer)
      render json: @user, methods: [:user_image_url]
    else
      render json: @user.errors, statut: :unprocessable_entity
    end
  end

  def updatedoctor
    @user = User.find(params[:id])

    if @user.update(post_params_doctor)

      render json: @user, methods: [:user_image_url]

    else
      render json: @user.errors, statut: :unprocessable_entity
    end
  end

  def updatepassword
    @user = User.find(params[:id])
      &.try(:authenticate, params[:password])
    if @user
      if params[:new_password] == params[:confirm_password]
        if @user.update(user_params)
          render json: {message: "Password successfully updated", user: @user}, methods: [:user_image_url], status: :ok
          Rails.logger.debug("Update failed due to: #{@user.errors.full_messages}")

        else
          render json: {errors: "fama chy"}
        end

      else
        render json: {error: "New password and confirmation do not match"}, status: :unprocessable_entity
      end

    else
      render json: {error: "Old password is incorrect"}, status: :unprocessable_entity
    end
  end

  def show_patients
    @doctor = Doctor.find(params[:id])

    @patients = @doctor.patients_with_consultations

    render json: @patients, status: :ok
  end

  def rate_doctor
    @consultation = Consultation.find(params[:consultation_id])
    @rating = Rating.new(rating_params)
    @rating.consultation = @consultation
    if @rating.save
      render json: @rating
    else
      render json: {error: "you already rate this doctor on that consultation"}, status: 800
    end
  end

  def check_rating
    consultation_id = params[:consultation_id]
    rating_exists = Rating.exists?(consultation_id: consultation_id)

    render json: {ratingExists: rating_exists}
  end

  # ON USE THIS TO HANDLE MULTIPLE SEARCH ON DOCTOR FOR SAME NAME OR LOCATION
  def search_doctors
    query = params[:query].to_s.strip.downcase
    location = params[:location].to_s.strip.downcase.presence # Ensure location is not empty
    cache_key = "doctor_search/#{query}_#{location}"

    doctors = Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      scope = Doctor.includes(:ratings, :phone_numbers)

      if query.present? && location.present?
        scope = scope.where(
          "(LOWER(firstname) LIKE :query OR LOWER(lastname) LIKE :query) AND LOWER(location) LIKE :location",
          query: "%#{query}%",
          location: "%#{location}%"
        )
      elsif query.present?
        scope = scope.where("LOWER(firstname) LIKE :query OR LOWER(lastname) LIKE :query", query: "%#{query}%")
      elsif location.present?
        scope = scope.where("LOWER(location) LIKE :location", location: "%#{location}%")
      end

      scope.as_json(
        only: [:id, :firstname, :lastname, :location, :address, :email_confirmed],
        methods: [:user_image_url],
        include: {
          phone_numbers: {only: [:number]},
          ratings: {only: [:id, :comment, :rating_value]}
        }
      )
      # #TO DO  WE  WILL ADD DOCTOR SEARCH BY SERVICE
    end

    # Add rating calculations in a single loop (avoid N+1 queries)
    doctors.each do |doctor|
      ratings = doctor["ratings"]
      doctor["rating_count"] = ratings.size
      doctor["total_rating_value"] = ratings.sum { |r| r["rating_value"] }
    end

    render json: doctors
  end

  def fetch_doctor_data
    doctor = Doctor.includes(:services, :ratings, :phone_numbers).find_by(id: params[:id])

    if doctor
      doctor_data = doctor.as_json(
        only: [:id, :firstname, :lastname, :location, :address, :email_confirmed, :latitude, :longitude, :about_me],
        methods: [:user_image_url],
        include: {
          phone_numbers: {only: [:number, :phone_type]},
          ratings: {
            only: [:id, :comment, :rating_value],
            include: {
              consultation: {
                include: {
                  patient: {
                    only: [:firstname, :lastname],
                    methods: [:user_image_url]
                  }
                }
              }
            }
          },
    services: {only: [:id, :name, :description, :price, :duration_minutes]}  # Include services here
        }
      )

      # Add rating calculations for the doctor
      ratings = doctor_data["ratings"]
      doctor_data["rating_count"] = ratings.size
      doctor_data["total_rating_value"] = ratings.sum { |r| r["rating_value"] }

      render json: doctor_data
    else
      render json: {error: "Doctor not found"}, status: :not_found
    end
  end

  private

  def paramsimagefreelancer
    params.permit(:id, :avatar)
  end

  def post_params_doctor
    params.permit(:id, :website, :facebook, :twitter, :youtube, :linkedin)
  end

  def user_params
    params.permit(:password, :newPassword, :confirmPassword, :id)
  end

  def rating_params
    params.permit(:consultation_id, :rating_value, :comment)
  end
end
