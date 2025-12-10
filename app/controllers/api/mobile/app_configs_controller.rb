require 'socket'

class Api::Mobile::AppConfigsController < ApplicationController
  def set_app_config
    host_value = params[:host]
    #Local Ip of Server machine
    #client_ip = request.remote_ip
    client_ip = Socket.ip_address_list
                     .select { |addr| addr.ipv4_private? && !addr.ip_address.start_with?("172.") }
                     .first&.ip_address
    #Rails port
    port =  "3001"
    #Combine format  Like "192.168.1.xx:3000"
    host_value = "#{client_ip}:#{port}"
    if host_value.present?
      app_config = AppConfig.find_or_create_by(key: "mobile")
      app_config.update(value: host_value)

      render json: { success: true, message: "Host updated successfully." }, status: :ok
    else
      render json: { success: false, message: "Invalid host value." }, status: :unprocessable_entity
    end
  end

end
