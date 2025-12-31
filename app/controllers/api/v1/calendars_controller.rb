class Api::V1::CalendarsController < ApplicationController
    def index
    render json: CalendarGenerator.generate(
      start_year: params[:start_year].to_i,
      years: 10
    )
  end
end

