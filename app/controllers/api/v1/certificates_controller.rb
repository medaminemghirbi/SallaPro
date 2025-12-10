class Api::V1::CertificatesController < ApplicationController
    before_action :authorize_request, only: [:create, :update, :destroy]
    before_action :set_consultation, only: [:show, :download]

    def show
        render json: certificate_data
    end
  
    private
  
    def set_consultation
      @consultation = Consultation.includes(:doctor, :patient).find(params[:id])
    end
  
    def certificate_data
      {
        doctor: {
          firstname: @consultation.doctor.firstname,
          lastname: @consultation.doctor.lastname,

          certification_number: @consultation.id,
          phone_numbers: @consultation.doctor.phone_numbers,
          email: @consultation.doctor.email,
          website: @consultation.doctor.website,
          twitter: @consultation.doctor.twitter,
          youtube: @consultation.doctor.youtube,
          facebook: @consultation.doctor.facebook,
          linkedin: @consultation.doctor.linkedin
        },
        patient: {
         firstname: @consultation.patient.firstname,
          lastname: @consultation.doctor.lastname,

          address: @consultation.patient.address,
          age: @consultation.patient.birthday
        },
        consultation: {
          date: @consultation.appointment,
          document_id: "#{@consultation.appointment.strftime('%Y%m%d')}",
          generated_on: "Generated on : -#{@consultation.appointment.strftime("%d-%m-%Y %H:%M:%S")}"
        }
      }
    end
end
