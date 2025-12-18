class ApplicationController < ActionController::API
  skip_before_action :verify_authenticity_token, raise: false

  # Fallback 404
  def not_found
    render json: { error: 'Not Found' }, status: :not_found
  end

  # JWT Authentication
  def authorize_request
    header = request.headers['Authorization']&.split(' ')&.last
    token  = header&.split(' ')&.last
    raise Warden::NotAuthenticated unless token
    return render_unauthorized('Missing token') unless header

    begin
      payload = JsonWebToken.decode(header)
      @current_user = User.find(payload[:user_id])

      # Check jti for token revocation
      unless @current_user.jti == payload[:jti]
        return render_unauthorized('Token has been revoked')
      end
    raise Warden::NotAuthenticated unless user.jti == payload[:jti]
    rescue ActiveRecord::RecordNotFound
      render_unauthorized('User not found')
    rescue JwtExpiredError
      render_unauthorized('Token has expired')
    rescue JwtInvalidError
      render_unauthorized('Invalid token')
    rescue StandardError => e
      render_unauthorized("Authentication error: #{e.message}")
    end
  end

  private

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
