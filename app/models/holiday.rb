class Holiday < ApplicationRecord
  self.table_name = "holidays"
  scope :current, -> { where(is_archived: false) }
  ## Validations
  validates :holiday_date, presence: true
  validates :holiday_name, presence: true
  def day_of_week
      # Check if holiday_date is present
      return nil unless holiday_date.present?
  
      # Parse the holiday_date string into a Date object
      date_object = Date.parse(holiday_date.to_s)
  
      # Get the day of the week (0 for Sunday, 1 for Monday, ..., 6 for Saturday)
      day_of_week = date_object.wday
  
      # Array of weekday names
      weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  
      # Get the name of the day of the week
      day_name = weekdays[day_of_week]
  
      # Return the day name
      day_name
    end
end