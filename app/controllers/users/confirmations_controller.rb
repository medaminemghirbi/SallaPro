# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      redirect_to 'http://localhost:4200/login'
    else
      render json: { error: 'There was a problem confirming your email.', details: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
