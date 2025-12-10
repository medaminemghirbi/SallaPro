class ReportMailer < ApplicationMailer
  default from: "DermaPro@System.com"

  def sent_email_to(patient, report_pdf_url)
    @patient = patient
    @report_pdf_url = report_pdf_url
    mail(to: @patient.email, subject: "Your Medical Report")
  end
end
