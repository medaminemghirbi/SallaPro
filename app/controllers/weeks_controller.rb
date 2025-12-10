# In your WeeksController
class WeeksController < ApplicationController
  def index
    doctor_id = params[:doctor_id]
    doctor = Doctor.find_by(id: doctor_id)
    days = generate_weekly_schedule(doctor)
    render json: days
  end

  private

  def generate_weekly_schedule(doctor)
    # Create an IceCube schedule starting from today
    schedule = IceCube::Schedule.new(Date.current) do |s|
      s.add_recurrence_rule(
        IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday, :thursday, :friday)
      )
      s.add_recurrence_rule(IceCube::Rule.weekly.day(:saturday)) if doctor&.working_saturday
    end

    # Exclude Sundays and generate dates for the next year
    schedule.occurrences(Date.current.end_of_year).map do |date|
      # Format the date as 'YYYY-MM-DD' and include the day name
      {day: date.strftime("%A"), date: date.strftime("%Y-%m-%d")}
    end
  end
end
