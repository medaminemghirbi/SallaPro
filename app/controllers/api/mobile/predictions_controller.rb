require "prawn"

class Api::Mobile::PredictionsController < ApplicationController
  def predict
    # Assuming the image is uploaded as part of the request
    image = params[:file]
    patient = Patient.find(params[:patient_id]) if params[:patient_id]
    doctor = Doctor.find(params[:doctor_id]) if params[:doctor_id]
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


    # Clean up the temporary file
    File.delete(image_path)

    # Save the PDF report to the database
    if patient
      prediction = Prediction.new(
        patient: patient,
        predicted_class: predicted_class,
        probability: probability,
        maladie: maladie
      )
    end
    if doctor
      prediction = Prediction.new(
        doctor: doctor,
        predicted_class: predicted_class,
        probability: probability,
        maladie: maladie
      )
    end



    if prediction.save
        render json: {
          predicted_class: prediction.predicted_class,
          probability: prediction.probability,
          maladie: prediction.maladie.as_json(methods: [:diseas_image_url_mobile])
        }
    else
        render json: { error: "Failed to save prediction and report" }, status: 500
    end         
  end


end
