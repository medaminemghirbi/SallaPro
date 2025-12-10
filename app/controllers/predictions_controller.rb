require "prawn"

class PredictionsController < ApplicationController
  def predict
    # Assuming the image is uploaded as part of the request
    image = params[:file]
    doctor = Doctor.find(params[:doctor_id])

    # Save the uploaded file to a temporary location
    sanitized_filename = image.original_filename.gsub(/\s+/, "_")
    image_path = Rails.root.join("tmp", sanitized_filename)
    File.binwrite(image_path, image.read)

    # Call the Machine Learning service with the image path
    prediction_output = RunMachineLearning.call(image_path)

    # Ensure the output is not nil or empty
    if prediction_output.nil? || prediction_output.empty?
      render json: {error: "Failed to get a valid prediction from the model"}, status: 500
      return
    end

    # Parse the output from the Python script
    lines = prediction_output.split("\n")

    if lines.size < 2
      render json: {error: "Prediction format is incorrect"}, status: 500
      return
    end

    # Parse predicted class and probability
    predicted_class = lines[0]&.gsub("Predicted class: ", "") || "Unknown"
    probability = lines[1]&.gsub("Probability: ", "").to_f || 0

    if predicted_class == "Other_Images"
      render json: {error: "This is not a skin disease image. Please Upload a valid skin image"}, status: 500
      return
    end
    maladie = Maladie.find_by(maladie_name: predicted_class)

    # Create a PDF medical report
    pdf_data = generate_pdf(predicted_class, probability, maladie, image_path)

    # Clean up the temporary file
    File.delete(image_path)

    # Save the PDF report to the database
    prediction = Prediction.new(
      doctor: doctor,
      predicted_class: predicted_class,
      probability: probability,
      maladie: maladie
    )
  # Conditionally assign consultation if provided
    if params[:consultation_id].present?
      consultation = Consultation.find_by(id: params[:consultation_id])
      prediction.consultation = consultation if consultation
    end

    prediction.report_pdf.attach(
      io: StringIO.new(pdf_data),
      filename: "prediction_report_#{Time.now.to_i}.pdf",
      content_type: "application/pdf"
    )

    if prediction.save
      render json: {predicted_class: predicted_class, maladie: maladie, probability: probability, report_url: url_for(prediction.report_pdf)}
    else
      render json: {error: "Failed to save prediction and report"}, status: 500
    end
  end

  def download
    doc = Prediction.find(params[:id])

    if doc.report_pdf.attached?
      begin
        pdf_data = doc.report_pdf.download # Download the file content
        send_data pdf_data, filename: "#{doc.predicted_class}.pdf", type: doc.report_pdf.content_type, disposition: "attachment"
        doc.update!(download_count: doc.download_count + 1)
        response.headers["X-Download-Count"] = doc.download_count.to_s
      rescue ActiveStorage::BlobError => e # Catch specific ActiveStorage errors
        puts "ActiveStorage Blob Error: #{e.message}"
        render plain: "Error accessing file.", status: :internal_server_error # More informative error
      rescue => e # Catch other potential errors
        puts "Other Error during download: #{e.message}"
        render plain: "Download error.", status: :internal_server_error # More informative error
      end
    else
      render plain: "PDF not found.", status: :not_found # Handle missing PDF
    end
  end

  def show
    doctor = Doctor.find(params[:id])

    predictions = Prediction.where(doctor_id: doctor.id, consultation_id: nil).order(created_at: :asc)
    # Use document_data method to include file_type and document_url
    render json: predictions.map { |doc| prediction_data(doc) }, status: :ok, methods: [:prediction_url]
  end

  def sent_report
    patient = Patient.find(params[:patient_id])
    prediction = Prediction.find(params[:prediction_id])
    report_pdf_url = prediction.prediction_url
    ReportMailer.sent_email_to(patient, report_pdf_url).deliver
    prediction.update(sent_at: Time.now)
  end



  def predictions_by_consultations
    consultation = Consultation.find(params[:consultation_id])
    predictions = Prediction.where(consultation_id: consultation.id).order(created_at: :asc)
    # Use document_data method to include file_type and document_url
    render json: predictions.map { |doc| prediction_data(doc) }, status: :ok, methods: [:prediction_url]
  end



  private

  # Method to format document data including file_type and document_url
  def prediction_data(doc)
    {
      id: doc.id,
      title: "#{doc.probability.to_i}% #{doc.predicted_class}.pdf ",
      created_at: doc.created_at,
      updated_at: doc.updated_at,
      createur: "Dr." + " " + doc.doctor.firstname + " " + doc.doctor.lastname,

      download_count: doc.download_count,

      file_type: doc.report_pdf.attached? ? doc.report_pdf.content_type : nil,  # Include file type
      size: doc.report_pdf.attached? ? (doc.report_pdf.blob.byte_size.to_f / 1_024).round(2) : 0,  # Convert size to KB
      sent_at: doc.sent_at,
      prediction_url: doc.report_pdf.attached? ? url_for(doc.report_pdf) : nil    # Include document URL
    }
  end

  def generate_pdf(predicted_class, probability, maladie, image_path)
    Prawn::Document.new do |pdf|
      # Title
      pdf.text "© DermaPro Medical App", size: 10, align: :right
      pdf.text "Medical Prediction Report", size: 24, style: :bold, align: :center
      pdf.move_down 3
      pdf.text "Generated on: #{Time.now.strftime("%d-%m-%Y %H:%M:%S")}", size: 10, align: :right
      pdf.stroke_horizontal_rule

      pdf.move_down 20

      # Prediction Details
      pdf.text "Prediction Details", size: 18, style: :bold
      pdf.move_down 10
      pdf.move_down 10
      pdf.text "Predicted Disease: #{predicted_class}", size: 14, style: :bold
      pdf.text "Probability: #{probability.round(2)}%", size: 14, style: :italic if probability.is_a?(Numeric)
      pdf.text "Scanned Image: ", size: 14, style: :italic
      scanned_image = image_path
      pdf.image scanned_image, width: 250, height: 125, position: :left

      pdf.move_down 20

      # Disease Information
      if maladie
        disease_image = maladie.image.attached? ? ActiveStorage::Blob.service.send(:path_for, maladie.image.key) : nil

        pdf.text "Disease Information", size: 18, style: :bold

        pdf.move_down 10
        pdf.text "Name: #{maladie.maladie_name}", size: 14, style: :bold
        pdf.text "Description: #{maladie.maladie_description}", size: 12
        pdf.text "Symptoms: #{maladie.symptoms}", size: 12
        pdf.text "Synonyms: #{maladie.synonyms}", size: 12
        pdf.text "Causes: #{maladie.causes}", size: 12
        pdf.text "Treatment: #{maladie.treatments}", size: 12
        pdf.text "Prevention: #{maladie.prevention}", size: 12
        pdf.text "Diagnosis: #{maladie.diagnosis}", size: 12
        pdf.text "References: #{maladie.references}", size: 12
        pdf.image disease_image, width: 250, height: 125, position: :center

      end

      # Footer
      pdf.move_down 20
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      pdf.image "app/assets/images/logo_with_beta.png", at: [pdf.bounds.right - 160, pdf.cursor], width: 150, height: 70
    end.render
  end
end
