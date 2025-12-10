class GenerateRoomCodeJob < ApplicationJob
  queue_as :default

  def perform
    Consultation.where(status: 1, appointment_type: 1).find_each do |consultation|
      if consultation.room_code.nil? || consultation.is_payed && consultation.room_code.empty? # && consultation.within_120_minutes_before_appointment?
        consultation.generate_room_code
        consultation.save!
        NotificationMailer.send_room_code(consultation.doctor, consultation.patient, consultation.room_code).deliver_later
      end
    end
  end
end
