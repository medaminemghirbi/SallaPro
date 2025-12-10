
require 'net/http'
require 'uri'
require 'json'

class Api::Mobile::ConsultationsController < ApplicationController
  before_action :authorize_request
  before_action :set_consultation, only: [:destroy, :update]
  def patient_consultations_today
    today = Date.current

    @consultations = Consultation.where(
      patient_id: params[:patient_id],
      appointment: today.beginning_of_day..today.end_of_day,
      status: 1
    ).sort_by(&:appointment)

    render json: @consultations.as_json(include: {
      doctor: {
        methods: [:user_image_url_mobile],
        include: {
          phone_numbers: { only: [:number] } # Include the phone number data
        }
      }
    }).map do |consultation|
      consultation.merge(
        appointment: consultation["appointment"].strftime("%Y-%m-%d %H:%M:%S")
      )
    end
  end

  def patient_appointments
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    @consultations = Consultation.current
                                .where(patient_id: params[:patient_id])
                                .page(page)
                                .per(per_page)
                                .order(appointment: :asc)
    render json: @consultations, include: {
      doctor: {
        only: [:firstname, :lastname, :address,:latitude,:longitude], methods: [:first_number, :user_image_url_mobile]
      },
      patient: { only: [:firstname, :lastname] }
    }
  end

  def destroy
    if @consultation.status == "pending"
      if @consultation.update(is_archived: true)
        render json: { message: "Consultation Deleted successfully." }, status: 200
      else
        render json: { error: "Failed to archive consultation." }, status: :unprocessable_entity
      end
    else
      render json: { error: "You can't delete this consultation." }, status: :unprocessable_entity
    end
  end



  
  def update
    @patient = User.find(@consultation.patient_id)

      if @consultation.update(consultation_params_update)
        #handle_sms(@consultation.patient_id, @consultation.doctor_id, @consultation)
        render json: @consultation
      else
        render json: @consultation.errors, status: :unprocessable_entity
      end
  rescue => e
    Rails.logger.error("Failed to update consultation: #{e.message}")
    render json: {error: e.message}, status: :internal_server_error
  end

##CREATE CONSULTATION BY Mobile 
def add_new_demande
  @consultation = Consultation.new(consultation_params)

  # Check if the request date is in the future
  if check_request_date?
    render json: { status: 422, error: "You cannot add a request date earlier than today." }, status: :unprocessable_entity
    return
  end

  # Check if the date is a holiday
  if holiday_exists?
    render json: { status: 422, error: "You cannot add a consultation on a holiday." }, status: :unprocessable_entity
    return
  end

  # Check if a consultation with another doctor already exists at the same time
  if consultation_with_other_doctor?
    render json: { status: 422, error: "You already have a consultation with a different doctor at the same time." }, status: :unprocessable_entity
    return
  end

  # Check if a consultation already exists for the same date and time
  if consultation_exists?
    render json: { status: 422, error: "You already created a consultation request on this date." }, status: :unprocessable_entity
    return
  end

  begin
    # Save the consultation
    if @consultation.save
      render json: { status: 200, message: "Consultation created successfully.", consultation: @consultation }
    else  
      render json: { status: 422, error: @consultation.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique => e
    # Handle the duplicate record error
    render json: { status: 409, error: "A consultation with this doctor on the same date already exists." }, status: :conflict
  end
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

  private

  def check_request_date?
    request_date = params[:appointment]
    if request_date.present? && request_date.to_date < Date.today
      return true
    end
    false
  end

  def holiday_exists?
    Holiday.where(holiday_date: @consultation.appointment).exists?
  end

  def consultation_exists?
    # Check if a consultation already exists for the same patient, doctor, and appointment time
    Consultation.where(
      appointment: @consultation.appointment,
      doctor_id: @consultation.doctor_id,
      patient_id: @consultation.patient_id
    ).where("DATE(appointment) = ?", @consultation.appointment.to_date)
    .exists?
  end

  def consultation_with_other_doctor?
    # Check if the same patient has another consultation at the same time with a different doctor
    Consultation.where(
      appointment: @consultation.appointment,
      patient_id: @consultation.patient_id
    ).where.not(doctor_id: @consultation.doctor_id).exists?
  end

  def set_consultation
    @consultation = Consultation.find(params[:id])
  end

  def consultation_params_update
    params.require(:consultation).permit(:id, :status, :refus_reason)
  end
  def consultation_params
    permitted_params = params.permit(:appointment, :status, :refus_reason, :is_archived, :doctor_id, :patient_id, :appointment_type, :note, :id)
    permitted_params[:appointment_type] = permitted_params[:appointment_type].to_i if permitted_params[:appointment_type].present?
    permitted_params
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
end