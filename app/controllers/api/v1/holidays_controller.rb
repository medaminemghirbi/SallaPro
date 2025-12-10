class Api::V1::HolidaysController < ApplicationController
  before_action :set_holiday, only: [:show, :update, :destroy]
  before_action :authorize_request
  def index
      @holidays = Holiday.order(:holiday_date).all.map { |holiday| holiday.attributes.merge(day_of_week: holiday.day_of_week) }
      render json: @holidays
  end
  def show
      render json: @holiday
  end
  def create
      @holiday = Holiday.new(holiday_params)
      if @holiday.save
      render json: @holiday, status: :created
      else
      render json: @holiday.errors, status: :unprocessable_entity
      end
  end
  def update
    if @holiday.update(holiday_params)
      render json: @holiday
    else
      render json: @holiday.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @holiday.update(is_archived: true)
  end

  private
    def set_holiday
      @holiday = Holiday.find(params[:id])
    end
    def holiday_params
      params.permit(:holiday_name, :holiday_date)
    end
end