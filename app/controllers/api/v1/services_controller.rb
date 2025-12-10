class Api::V1::ServicesController < ApplicationController
  before_action :authorize_request
  def index
    @services = Service.all.order(:order)
    render json: @services
  end

  def doctor_services
    doctor = Doctor.includes(:doctor_services, :services).find_by(id: params[:id])

    if doctor
      doctor_services = doctor.services.map do |service|
        doctor_service = doctor.doctor_services.find_by(service_id: service.id)
        {
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price,
          doctor_service_id: doctor_service&.id # Include the doctor_service.id
        }
      end

      render json: doctor_services
    else
      render json: {error: "Doctor not found"}, status: :not_found
    end
  end

  def doctor_add_services
    doctor = Doctor.find_by(id: params[:id])

    if doctor
      service_ids = service_params[:service_ids]
      created_services = []

      service_ids.each do |service_id|
        existing_service = DoctorService.find_by(doctor_id: doctor.id, service_id: service_id)
        if existing_service
          render json: {error: "Service #{existing_service.service.name} is already assigned to this doctor."}, status: :unprocessable_entity
        else
          new_doctor_service = DoctorService.new(doctor_id: doctor.id, service_id: service_id)
          if new_doctor_service.save
            created_services << new_doctor_service
          else
            render json: {error: new_doctor_service.errors.full_messages}, status: :unprocessable_entity
          end
        end
      end
      render json: created_services.as_json(only: [:id, :doctor_id, :service_id]), status: :created
    else
      render json: {error: "Doctor not found"}, status: :not_found
    end
  end

  def destroy
    @doctor_service = DoctorService.find(params[:id])
    @doctor_service.destroy
  end

  private

  def service_params
    params.permit(service_ids: [])
  end
end
