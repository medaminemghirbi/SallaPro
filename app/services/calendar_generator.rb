class CalendarGenerator
  def self.generate(start_year:, years:)
    end_year = start_year + years - 1

    (start_year..end_year).map do |year|
      {
        year: year,
        months: (1..12).map do |month|
          first_day = Date.new(year, month, 1)
          last_day  = first_day.end_of_month

          {
            month: first_day.strftime("%B"),
            month_number: month,
            days: (first_day..last_day).map do |day|
              {
                date: day,
                day: day.day,
                weekday: day.strftime("%A"),
                weekday_index: day.cwday # 1=Mon, 7=Sun
              }
            end
          }
        end
      }
    end
  end
end
