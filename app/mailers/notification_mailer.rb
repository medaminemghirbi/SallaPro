# app/mailers/notification_mailer.rb
class NotificationMailer < ApplicationMailer
  def send_room_code(doctor, patient, room_code)
    @doctor = doctor
    @patient = patient
    @room_code = room_code

    # Prepare email subject and body
    email_subject = "Your Consultation Room Link"
    email_body = "Hello,<br>Your consultation room link  for online consultation is: <strong><a href='http://localhost:4200/live/#{@room_code}'>Join Consultation</a></strong><br>Best regards,<br> Doc Pro System"

    # Send email to patient
    mail(to: @patient.email, subject: email_subject) do |format|
      format.html { render "send_room_code" }
    end

    # Send email to doctor
    mail(to: @doctor.email, subject: email_subject) do |format|
      format.html { render "send_room_code" }
    end

    # Track sent email in the database
    CustomMail.create!(
      doctor_id: @doctor.id,
      patient_id: @patient.id,
      subject: email_subject,
      body: email_body,
      status: "sent",
      sent_at: Time.current
    )

    # Broadcast the email details via Action Cable
    ActionCable.server.broadcast "MailChannel", {
      doctor_id: @doctor.id,
      patient_id: @patient.id,
      subject: email_subject,
      body: email_body,
      status: "sent",
      sent_at: Time.current
    }
  end
end
