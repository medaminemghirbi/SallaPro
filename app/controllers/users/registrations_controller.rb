# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: { message: 'Signed up successfully.', user: resource }, status: :ok
    else
      render json: { message: 'Sign up failed.', errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end 
  def create
    user_class = case sign_up_params[:type]
                 when "Admin" then User
                 when "Doctor" then Doctor
                 else Patient
                 end
  
    build_resource(sign_up_params.merge(type: user_class.name, plateform: 0))
    resource.save
    if resource.persisted?
      UserMailer.registration_confirmation(resource).deliver_later
      render json: { message: 'Signed up successfully.', user: resource }, status: :created
    else
      render json: { message: 'Sign up failed.', errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end  
  private

  def sign_up_params
    params.require(:registration).permit(:lastname, :firstname, :email, :password, :password_confirmation, :type, :location, :gender)
  end
end
