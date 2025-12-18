# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authorize_request, raise: false
  respond_to :json

  # 🔐 Explicit authentication
  def create
    user = User.find_by(email: sign_in_params[:email])

    unless user&.valid_password?(sign_in_params[:password])
      return render json: { error: 'Invalid email or password' }, status: :unauthorized
    end

    # Let Devise/Warden finish authentication
    self.resource = user
    sign_in(resource_name, user)

    respond_with user
  end

  private

  # 🔐 Response after successful authentication
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

  def respond_to_on_destroy
    token = request.headers['Authorization']&.split(' ')&.last

    return render json: { message: 'Token missing.' }, status: :unauthorized if token.blank?

    begin
      JsonWebToken.decode(token)
      Rails.cache.delete("blacklist/#{token}")
      render json: { message: 'Logged out successfully.' }, status: :ok
    rescue JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature
      render json: { message: 'Logged out (invalid or expired token).' }, status: :ok
    end
  end

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end
