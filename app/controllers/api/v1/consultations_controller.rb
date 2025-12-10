
require 'net/http'
require 'uri'
require 'json'

class Api::V1::ConsultationsController < ApplicationController
  before_action :set_consultation, only: [:update, :destroy]

  # GET /consultations
  def index
    render json: Consultation.current
  end

  # POST /consultations
  def create
    @consultation = Consultation.new(consultation_params)
    validator = ConsultationValidator.new(@consultation, params)

    if validator.check_request_date_invalid?
      render json: { error: "You cannot add a request date earlier than today." }, status: 800 and return
    end

    if validator.holiday_exists?
      render json: { error: "You cannot add a consultation on a holiday." }, status: 800 and return
    end

    if validator.consultation_with_other_doctor?
      render json: { error: "You cannot create a consultation at the same time with a different doctor." }, status: 800 and return
    end
    
    if validator.consultation_exist_on_date?
      render json: { error: "You already created a consultation request on this date." }, status: 800 and return
    end
    if @consultation.save
      handle_notifications(@consultation.patient_id, @consultation.doctor_id, @consultation)
      render json: @consultation, status: :created
    else
      render json: @consultation.errors, status: 800
    end
  end

  # PATCH/PUT /consultations/1
  def update
    @patient = User.find(@consultation.patient_id)

    if valid_status?(consultation_params[:status])
      if @consultation.update(consultation_params)
        handle_notifications(@consultation.patient_id, @consultation.doctor_id, @consultation)
        handle_sms(@consultation.patient_id, @consultation.doctor_id, @consultation)
        send_push_notification(@patient.expo_push_token, "Consultation Updated", "Your consultation has been updated.")
        render json: @consultation
      else
        render json: @consultation.errors, status: :unprocessable_entity
      end
    else
      render json: {error: "Invalid status"}, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("Failed to update consultation: #{e.message}")
    render json: {error: e.message}, status: :internal_server_error
  end


  def show
    @consultation = Consultation.find(params[:id])
    render json: @consultation
  end

  # DELETE /consultations/1
  def destroy
    if @consultation.status == "pending" || @consultation.status == "canceled"
      @consultation.update(is_archived: true)
    else
      render json: {error: "You can't delete it."}, status: :unprocessable_entity
    end
  end

  # GET /consultations/doctor_appointments
  def doctor_appointments
    @consultations = Consultation.current.where(doctor_id: params[:doctor_id]).order(appointment: :asc)
    render json: @consultations, include: {
      doctor: {
        methods: [:user_image_url],
        include: :phone_numbers  # Include phone_numbers here
      },
      patient: {methods: [:user_image_url]}
    }
  end

  def patient_appointments
    @consultations = Consultation.current.where(patient_id: params[:patient_id]).order(appointment: :asc)
    render json: @consultations, include: {
      doctor: {
        methods: [:user_image_url],
        include: :phone_numbers
      },
      patient: {methods: [:user_image_url]}
    }
  end

  # GET /consultations/doctor_consultations
  def doctor_consultations
    @consultations = Consultation.current.where(doctor_id: params[:doctor_id], status: 1)
    rendered_consultations = @consultations.map do |consultation|
      consultation_hash = consultation.as_json(include: {
        doctor: {
          methods: [:user_image_url],
          include: :phone_numbers
        },
        patient: {methods: [:user_image_url]}
      })

      consultation_hash[:appointment] = consultation.appointment.in_time_zone("Africa/Tunis").strftime("%Y-%m-%d %H:%M:%S")

      consultation_hash
    end

    render json: rendered_consultations
  end

  # GET /consultations/doctor_consultations_today
  def doctor_consultations_today
    today = Date.current

    @consultations = Consultation.where(
      doctor_id: params[:doctor_id],
      appointment: today.beginning_of_day..today.end_of_day,
      status: 1
    ).sort_by(&:appointment)

    render json: @consultations.as_json(include: {
      patient: {methods: [:user_image_url]}
    }).map do |consultation|
      consultation.merge(
        appointment: consultation["appointment"].strftime("%Y-%m-%d %H:%M:%S")
      )
    end
  end

  # GET /consultations/available_time_slots
  def available_time_slots
    doctor_id = params[:doctor_id]
    date_str = params[:date]
    date = Date.parse(date_str)
    start_of_day = date.beginning_of_day.in_time_zone("Africa/Tunis")
    end_of_day = date.end_of_day.in_time_zone("Africa/Tunis")

    approved_consultations = Consultation.where(
      doctor_id: doctor_id,
      status: 1,
      appointment: start_of_day..end_of_day
    )

    # Collect occupied slots
    occupied_slots = approved_consultations.pluck(:appointment).map do |appointment|
      appointment.in_time_zone("Africa/Tunis").strftime("%H:%M")
    end

    # Prepare available and unavailable slots
    available_slots = TIME_SLOTS.reject { |slot| occupied_slots.include?(slot[:time]) }
    unavailable_slots = TIME_SLOTS.select { |slot| occupied_slots.include?(slot[:time]) }

    # Combine available and unavailable slots into a response
    response = {
      available_slots: available_slots,
      unavailable_slots: unavailable_slots
    }

    render json: response
  end

  def code_room_exist
    consultation = Consultation.find_by(room_code: params[:code])
    if consultation
      render json: consultation, status: :ok
    else
      render json: {error: "Consultation with the specified room code does not exist."}, status: :unprocessable_entity
    end
  end

  # ON USE THIS TO HANDLE MULTIPLE SEARCH ON DOCTOR FOR SAME NAME OR LOCATION
  def search_doctors
    query = params[:query]
    cache_key = "doctor_search/#{query}"

    # Try to fetch from cache
    doctors = Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      Doctor.where("firstname ILIKE :query OR location ILIKE :query", query: "%#{query}%")
        .includes(:phone_numbers)
        .as_json(only: [:id, :firstname, :lastname], include: :phone_numbers)
    end
    render json: doctors
  end

  private

  def set_consultation
    @consultation = Consultation.find(params[:id])
  end

  def consultation_params
    permitted_params = params.permit(:appointment, :status, :refus_reason, :is_archived, :doctor_id, :patient_id, :appointment_type, :note, :id)
    permitted_params[:appointment_type] = permitted_params[:appointment_type].to_i if permitted_params[:appointment_type].present?
    permitted_params
  end

  def valid_status?(status)
    %w[pending rejected approved canceled].include?(status)
  end

  def handle_notifications(patient_id, doctor_id, consultation)
    notification_service = NotificationService.new(consultation)
    notification_service.send_notifications
  end

  def handle_sms(patient_id, doctor_id, consultation)
    notification_service = NotificationService.new(consultation)
    notification_service.send_sms_notifications
  end
  def send_push_notification(token, title, body)
    return if token.blank?
  
    uri = URI.parse('https://exp.host/--/api/v2/push/send')
    header = { 'Content-Type': 'application/json' }
    message = {
      to: token,
      sound: 'default',
      title: title,
      body: body,
      data: { updated: true }
    }
  
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = message.to_json
    response = http.request(request)
    Rails.logger.info("Expo push response: #{response.body}")
  end
  TIME_SLOTS = [
    {time: "09:00"},
    {time: "09:30"},
    {time: "10:00"},
    {time: "10:30"},
    {time: "11:00"},
    {time: "11:30"},
    {time: "12:00"},
    {time: "13:30"},
    {time: "14:00"},
    {time: "14:30"},
    {time: "15:00"},
    {time: "15:30"},
    {time: "16:00"}
  ]
end
