module CurrentUserConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  def set_current_user
    header = request.headers['Authorization']
    token  = header&.split(' ')&.last
    return unless token

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload['user_id'] || payload[:user_id])
    return unless @current_user

    # JTI verification
    @current_user = nil unless @current_user.jti == payload['jti']
  rescue StandardError
    @current_user = nil
  end
end
