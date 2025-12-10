class PhoneVerificationService
  def initialize(user)
    @user = user
    @user = User.find(@user.id)
  end

  def send_otp_to_patient
    @user.confirmation_code = generate_confirmation_code
    @user.confirmation_code_generated_at = Time.current
    @user.save!
    # Concatenate the generated confirmation code to the message
    message = "Your Verification Code is #{@user.confirmation_code}."
    
    # Sending SMS using Twilio
    sms_sender = Twilio::SmsSender.new(
      body: message,
      to_phone_number: @user.phone_number
    )
    sms_sender.send_sms
  rescue => e
    Rails.logger.error("Error sending SMS to person: #{e.message}")
  end

  private

  def generate_confirmation_code
    rand.to_s[2..7]
  end
  
end
