class Api::V1::PhoneNumbersController < ApplicationController
  before_action :set_phone_number, only: [:show, :edit, :update, :destroy]

  # GET /doctors/:doctor_id/phone_numbers
  def index
    if params[:doctor_id].present?
      @phone_numbers = PhoneNumber.current.where(doctor_id: params[:doctor_id])
    end
    render json: @phone_numbers
  end

  # POST /phone_numbers
  def create
    @doctor = Doctor.find(params[:phone_number][:doctor_id])
    @phone_number = @doctor.phone_numbers.build(phone_number_params)
  
    if @phone_number.save
      render json: @phone_number, status: :created
    else
      render json: @phone_number.errors, status: :unprocessable_entity
    end
  end

  # PUT /phone_numbers/:id
  def update
    if @phone_number.update(phone_number_params)
      render json: @phone_number
    else
      render json: @phone_number.errors, status: :unprocessable_entity
    end
  end

  # DELETE /phone_numbers/:id
  def destroy
    if @phone_number.update(is_archived: true)
      render json: { message: 'Phone number archived successfully' }, status: :ok
    else
      render json: { error: 'Failed to delete phone number' }, status: :unprocessable_entity
    end
  end

  private

  def set_phone_number
    @phone_number = PhoneNumber.find(params[:id])
  end

  def phone_number_params
    params.require(:phone_number).permit(:number, :phone_type, :doctor_id)
  end
end
