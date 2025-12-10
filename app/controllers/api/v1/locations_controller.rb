require 'net/http'
class Api::V1::LocationsController < ApplicationController
  before_action :authorize_request
  def details
    latitude = params[:latitude]
    longitude = params[:longitude]
    
    if latitude.present? && longitude.present?
      # Call Google Geocoding API to get location details
      api_key = "AIzaSyCvRxK4LMfilsJB75r-ZcjE4Q6jllSUMhU"
      url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{latitude},#{longitude}&key=#{api_key}"
      
      uri = URI(url)
      response = Net::HTTP.get(uri)
      location_data = JSON.parse(response)
      if location_data['status'] == 'OK'
        address_details = location_data['results'].first['formatted_address']
        render json: { address: address_details }
      else
        render json: { error: 'Location not found' }, status: 422
      end
    else
      render json: { error: 'Invalid coordinates' }, status: 400
    end
  end
  def update_address
    latitude = params[:latitude]
    longitude = params[:longitude]
    if latitude.present? && longitude.present?
      # Call Google Geocoding API to get location details
      api_key = "AIzaSyCvRxK4LMfilsJB75r-ZcjE4Q6jllSUMhU"
      url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{latitude},#{longitude}&key=#{api_key}"
      
      uri = URI(url)
      response = Net::HTTP.get(uri)
      location_data = JSON.parse(response)
      
      if location_data['status'] == 'OK'
        address_details = location_data['results'].first['formatted_address']
        
        # Update the current user's address
        current_user = User.find(params[:id])
        if current_user.update(address: address_details)
          render json: { user: current_user, message: 'Address updated successfully' }
        else
          render json: { error: 'Failed to update address' }, status: 422
        end
      else
        render json: { error: 'Location not found' }, status: 422
      end
    else
      render json: { error: 'Invalid coordinates' }, status: 400
    end
  end
end
