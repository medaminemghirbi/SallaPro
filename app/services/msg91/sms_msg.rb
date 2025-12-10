require 'net/http'
require 'uri'
require 'json'

module Msg91
  class SmsMsg
    AUTH_KEY = ENV['AUTHKEY']
    TEMPLATE_CONFIRMATION_ID = ENV["TEMPLATE_CONFIRMATION_ID"]
    API_URL = "https://control.msg91.com/api/v5/flow/"

    def initialize(body:, to_phone_number:, vars: {})
      @body = body
      @to_phone_number = to_phone_number
      @vars = vars
      validate_environment_variables
    end

    def send_sms_confirmation
      uri = URI(API_URL)
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request['authkey'] = AUTH_KEY

      payload = {
        "template_id" => TEMPLATE_CONFIRMATION_ID,
        "short_url" => "0",
        "realTimeResponse" => "1",
        "recipients" => [
          {
            "mobiles" => @to_phone_number
          }.merge(@vars.transform_keys(&:to_s))
        ]
      }

      request.body = payload.to_json
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

      JSON.parse(response.body)
    end

    private

    def validate_environment_variables
      raise "AUTHKEY is missing in ENV" unless AUTH_KEY
    end
  end
end
