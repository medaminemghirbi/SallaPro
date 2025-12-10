class ConsultationValidator
    def initialize(consultation, params)
      @consultation = consultation
      @params = params
    end
  
    def check_request_date_invalid?
      request_date = Date.parse(@params[:appointment]) if @params[:appointment].present?
      request_date.present? && request_date < Date.today
    end
  
    def holiday_exists?
      Holiday.exists?(holiday_date: @consultation.appointment)
    end
  
    def consultation_with_other_doctor?
      Consultation.where(
        appointment: @consultation.appointment,
        patient_id: @consultation.patient_id
      ).where.not(doctor_id: @consultation.doctor_id).exists?
    end

    def consultation_exist_on_date?
      Consultation.where(
        patient_id: @consultation.patient_id
      ).where('DATE(appointment) = ?', @consultation.appointment.to_date).exists?
    end
  end
  