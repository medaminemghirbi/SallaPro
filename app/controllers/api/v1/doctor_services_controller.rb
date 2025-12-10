class Api::V1::DoctorServicesController < ApplicationController
  before_action :authorize_request
  def destroy
    @doctor_service = DoctorService.find(params[:id])
    @doctor_service.destroy
  end

  private

  def service_params
    params.permit(service_ids: [])
  end
end
