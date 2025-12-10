class Prediction < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :doctor, class_name: "User", optional: true 
  belongs_to :patient, class_name: "User", optional: true 

  belongs_to :maladie
  has_one_attached :report_pdf
  belongs_to :consultation, optional: true 
  def prediction_url
    # Get the URL of the associated image using the attached report_pdf
    report_pdf.attached? ? url_for(report_pdf) : nil
  end
end
