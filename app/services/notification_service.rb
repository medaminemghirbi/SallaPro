class NotificationService
    def initialize(reservation)
      @reservation = reservation
      @client = User.find(@reservation.client_id)
      @company = User.find(@reservation.company_id)
    end
  
    def send_notifications
      send_email_notifications
      send_push_notifications
    end
  
    def send_sms_notifications
      send_sms_to_patient if @patient.is_smsable
    end
  
    private
  
    def send_email_notifications
      send_email(@doctor) if @doctor.is_emailable
      send_email(@patient) if @patient.is_emailable
    end
  
    def send_push_notifications
      send_push(@doctor) if @doctor.is_notifiable
      send_push(@patient) if @patient.is_notifiable
    end
  
    def send_email(user)
      DemandeMailer.send_mail_demande(user, @reservation).deliver
    end
  
    def send_push(user)
      ActionCable.server.broadcast "reservationChannel_#{user.id}", {
        reservation: @reservation,
        status: @reservation.status
      }
    end
    
    def send_sms_to_patient
      message = "Your request with the company has been accepted. Check your account."
      sms_sender = Twilio::SmsSender.new(
        body: message,
        to_phone_number: @company.phone_number
      )
      sms_sender.send_sms
    rescue => e
      Rails.logger.error("Error sending SMS to patient: #{e.message}")
    end
  end
  