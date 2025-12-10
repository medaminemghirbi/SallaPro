require 'faker'
require 'json'
require 'csv'
require 'open-uri'
class Api::V1::ScrapersController < ApplicationController
  def run

    # Check if the CSV file exists
    RunScraper.call
    csv_file_path = Rails.root.join("app/services/dermatologue_doctors.csv")
    last_run_file = Rails.root.join("app/services/last_scraper_run.json")

    # Process CSV data
    CSV.foreach(csv_file_path, headers: true) do |row|
      firstname = row['name'].split(' ')[0]
      lastname = row['name'].split(' ')[1..].join(' ')
      location = row['location']

      doctor_exists = Doctor.exists?(firstname: firstname, lastname: lastname, location: location)

      unless doctor_exists
        doctor = User.create!(
          firstname: firstname,
          lastname: lastname,
          location: location,
          address: row['description'],
          #google_maps_url: row['google_maps_url'],
          phone_number: row['phone_number'].presence || "",
          email: "#{lastname.downcase.gsub(' ', '.')}.#{firstname.downcase.gsub(' ', '.')}@gmail.com",
          password: "123456",
          created_at: Faker::Date.between(from: Date.parse('2025-01-01'), to: Date.parse('2025-08-01')),
          password_confirmation: "123456",
          type: "Doctor",
          confirmed_at: Time.now
        )

        # Download and attach the avatar if present
        if row['avatar_src'].present?
          avatar_url = row['avatar_src']
          avatar_file = URI.open(avatar_url)
          doctor.avatar.attach(io: avatar_file, filename: File.basename(avatar_url), content_type: avatar_file.content_type)
        end
      end
    end

    # Record the time of this execution
    File.open(last_run_file, 'w') do |f|
      f.write({ last_run: Time.current.to_s }.to_json)
    end

    render json: { message: "Doctors successfully imported!" }
  end


  def last_run
    last_run_file = Rails.root.join('app/services/last_scraper_run.json')
    if File.exist?(last_run_file)
      last_run_data = JSON.parse(File.read(last_run_file))
      render json: { last_run: last_run_data['last_run'] }, status: :ok
    else
      render json: { message: "No record of last run found." }, status: :not_found
    end
  end
end
