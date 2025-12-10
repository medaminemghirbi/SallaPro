module Twilio
  class SmsSender
    TWILIO_ACCOUNT_SID = ENV['TWILIO_ACCOUNT_SID']
    TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN']
    TWILIO_MESSAGING_SERVICE_SID = ENV['TWILIO_MESSAGING_SERVICE_SID']
    TWILIO_FROM_PHONE = ENV['TWILIO_FROM_PHONE']
    TWILIO_TEST_PHONE = ENV['TWILIO_TEST_PHONE']
    def initialize(body:, to_phone_number:)
      @body = body
      @to_phone_number = to_phone_number
      validate_environment_variables
    end

    def send_sms
      @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

      begin
        message = @client.messages.create(
          body: @body,
          from: TWILIO_FROM_PHONE,
          to: to(@to_phone_number)
        )
        Rails.logger.info("Message sent successfully: #{message.sid}")
      rescue Twilio::REST::RestError => e
        Rails.logger.error("Failed to send message: #{e.message}")
        raise "Twilio SMS Error: #{e.message}"
      end
    end

    private

    def to(to_phone_number)
      # Use test phone number in development mode
      return TWILIO_TEST_PHONE if Rails.env.development? && TWILIO_TEST_PHONE.present?

      # Ensure the number starts with +216
      formatted_number = to_phone_number.gsub(/\s+/, "") # Remove spaces
      formatted_number = formatted_number.start_with?("+216") ? formatted_number : "+216#{formatted_number}"

      formatted_number
    end
    def validate_environment_variables
      missing_vars = []
      missing_vars << 'TWILIO_ACCOUNT_SID' if TWILIO_ACCOUNT_SID.blank?
      missing_vars << 'TWILIO_AUTH_TOKEN' if TWILIO_AUTH_TOKEN.blank?
      missing_vars << 'TWILIO_MESSAGING_SERVICE_SID' if TWILIO_MESSAGING_SERVICE_SID.blank?

      unless missing_vars.empty?
        raise "Missing environment variables: #{missing_vars.join(', ')}"
      end
    end
  end
end