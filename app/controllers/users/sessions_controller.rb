# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      token = JsonWebToken.encode(user_id: resource.id)
      exp_time = 24.hours.from_now

      # Optional blacklist on login if you want future logout control
      Rails.cache.write("blacklist/#{token}", true, expires_in: exp_time - Time.current)

      qr_login_url = "myapp://qr-login?token=#{token}"
      render json: {
        logged_in: true,
        user: UserSerializer.new(resource),
        type: resource.type,
        token: token,
        qr_url: qr_login_url,
        exp: exp_time.strftime("%m-%d-%Y %H:%M")
      }, status: :ok
    else
      render json: { logged_in: false, message: 'Login failed', errors: resource.errors.full_messages }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    token = request.headers['Authorization']&.split(' ')&.last

    if token.blank?
      render json: { message: 'Token missing.' }, status: :unauthorized
      return
    end

    begin
      JsonWebToken.decode(token)
      Rails.cache.delete("blacklist/#{token}") if Rails.cache.exist?("blacklist/#{token}")
      render json: { message: 'Logged out successfully.' }, status: :ok

    rescue JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature
      render json: { message: 'Logged out (invalid or expired token).' }, status: :ok
    end
  end
end
