class Api::Mobile::AuthController < ApplicationController
    before_action :authorize_request
    def verify
        render json: { message: 'Token is valid' }, status: :ok
    end
end
