class Users::SessionsController < Devise::SessionsController
  skip_before_action :authorize_request, raise: false
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    resource.update!(jti: SecureRandom.uuid)

    token = JsonWebToken.encode(
      user_id: resource.id,
      jti: resource.jti
    )

    render json: {
      logged_in: true,
      user: UserSerializer.new(resource),
      type: resource.type,
      token: token,
      exp: 3.hours.from_now.strftime("%m-%d-%Y %H:%M")
    }, status: :ok
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
