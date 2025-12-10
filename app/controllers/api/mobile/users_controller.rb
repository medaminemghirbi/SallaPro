class Api::Mobile::UsersController < ApplicationController
    def update_settings
        @user = User.find(params[:id])
        if @user.update(params_informations_user)
          render json: @user, methods: [:user_image_url_mobile]
        else
          render json: @user.errors, statut: :unprocessable_entity
        end
    end
    def save_token
      user = User.find(params[:user_id])
      user.update!(expo_push_token: params[:expo_push_token])
      render json: { success: true }
    end
    private
    def params_image_user
      params.permit(:id, :avatar)
    end

    def params_informations_user
      permitted_params = params.permit(:id, :birthday, :lastname, :firstname, :location,
                                       :is_emailable,  :is_notifiable, :is_smsable, :phone_number, :language, :avatar, :password, :password_confirmation)
      permitted_params
    end
end