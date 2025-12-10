class Api::V1::PatientsController < ApplicationController
  before_action :set_patient, only: [:destroy]
  before_action :authorize_request
    def  index
      @patients = Patient.current.all
      render json: @patients.map { |patient|
      patient.as_json(methods: [:user_image_url]).merge(confirmed_at: patient.confirmed_at)
    }
    end

  def destroy
    @Patient = Patient.find(params[:id])
    @Patient.update(is_archived: true)
  end

  def getPatientStatistique
    @consultations = Consultation.current.where(patient_id: params[:patient_id]).count
    render json: {
      consultation: @consultations
    }
  end
  #************************* les fonctions private de classe ***********************#

  private

  def set_patient
    @Patient = Patient.find(params[:id])
  end

end
