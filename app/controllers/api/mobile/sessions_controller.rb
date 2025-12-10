class Api::Mobile::SessionsController < ApplicationController
include CurrentUserConcern
    def sign_in_mobile
        @user = User
            .find_by(email: params['user']['email'])
            &.try(:authenticate, params['user']['password'])
        if @user
            token = JsonWebToken.encode(user_id: @user.id)
            time = Time.now + 24.hours.to_i
            Rails.cache.write("blacklist/#{token}", true, expires_in: time.to_i - Time.now.to_i)
            render json: {
                logged_in: true,
                user: @user.as_json(methods: [:user_image_url_mobile]),
                type: @user.type,
                token: token,
                exp: time.strftime("%m-%d-%Y %H:%M")
            }
        else
            render json: { status: 401 }
        end
    end
    def resend_confirm_link
        @user = User.find_by(email: params['user']['email'])&.try(:authenticate, params['user']['password'])
        if @user
            if @user.email_confirmed == false
                @user.update(confirm_token: SecureRandom.urlsafe_base64.to_s) if @user.confirm_token.blank?
                UserMailer.registration_confirmation(@user).deliver_now
                render json: { message: 'A new confirmation email has been sent to your email address.' }, status: :ok
            else
                render json: { error: 'Your email is already confirmed.' }, status: :unprocessable_entity
            end
        else
            render json: { error: 'Invalid email or password.' }, status: :unauthorized
        end
    end

    def logged_in
        if @current_user
            render json: {
                logged_in: true,
                user: @current_user
            }
        else
            render json: {
                logged_in: false
            }
        end
    end
    def logout
        token = request.headers['Authorization']&.split(' ')&.last
        if token.present?
            # Remove the token from the blacklist cache
            Rails.cache.delete("blacklist/#{token}")
        end

        reset_session
        render json: { status: 200, logged_out: true }
    end

    def login_qr
    token = params[:token]
    begin
      # Decode JWT token
      decoded_token = JsonWebToken.decode(token)
      user_id = decoded_token['user_id']
      exp = decoded_token['exp']

      if Time.now.to_i > exp
        render json: { error: 'Token expired' }, status: :unauthorized and return
      end

      user = User.find_by(id: user_id)
      if user
        render json: {
            logged_in: true,
            user: user.as_json(methods: [:user_image_url_mobile]),
            type: user.type,
            token: token
        }
      else
        render json: { error: 'User not found' }, status: :unauthorized
      end

    rescue JWT::DecodeError
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end
end