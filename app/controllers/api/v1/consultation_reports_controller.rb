require "prawn"

class Api::V1::ConsultationReportsController < ApplicationController
    before_action :set_consultation, only: [:create, :show, :download, :preview]
  
    # POST /consultations/:consultation_id/consultation_reports
    def create
      @consultation_report = @consultation.build_consultation_report(consultation_report_params)
  
      if @consultation_report.save
        render json: { message: 'Consultation report created successfully' }, status: :created
      else
        render json: { errors: @consultation_report.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    # GET /consultations/:consultation_id/report
    def show
      if @consultation.has_report?
        render json: { 
          reportExists: true, 
          report: @consultation.consultation_report, 
          consultation: @consultation, 
          patient: {
            firstname: @consultation.patient.firstname,
            lastname: @consultation.patient.lastname,
          }
        }
      else
        render json: { reportExists: false,
        consultation: @consultation, 
        patient: {
          firstname: @consultation.patient.firstname,
          lastname: @consultation.patient.lastname,
        }

      }
      end
    end
  
    # GET /consultations/:consultation_id/report/download
    def download
      if @consultation.has_report?
        report = @consultation.consultation_report
        pdf = generate_pdf(report) # Generate PDF logic here
        send_data pdf.render, filename: "consultation-report-#{@consultation.patient.firstname} #{@consultation.patient.lastname}.pdf", type: "application/pdf", disposition: "inline"
      else
        render json: { error: 'No report available to download' }, status: :not_found
      end
    end
  


    private
  
    # Sets the consultation based on the provided consultation_id
    def set_consultation
      @consultation = Consultation.find(params[:consultation_id])
    end
  
    # Strong params for the consultation report
    def consultation_report_params
      params.require(:consultation_report).permit(:diagnosis, :procedures, :prescription, :doctor_notes, images: [])
    end
  
    def generate_pdf(report)
      Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: [50]) do |pdf|
        # Set default font
        pdf.font_families.update("Helvetica" => {
          normal: "Helvetica",
          bold: "Helvetica-Bold",
          italic: "Helvetica-Oblique",
          bold_italic: "Helvetica-BoldOblique"
        })
        pdf.font "Helvetica"
        
        # Header with logo and metadata
        pdf.bounding_box([0, pdf.bounds.top + 40], width: pdf.bounds.width) do
          pdf.image "app/assets/images/logo_with_beta.png", width: 120, position: :left
          pdf.move_down 10
          pdf.text "CONFIDENTIAL MEDICAL REPORT", size: 8, align: :right, style: :bold
          pdf.text "Generated: #{Time.now.strftime("%B %d, %Y at %H:%M")}", size: 8, align: :right
        end
        
        pdf.move_down 30
        
        # Title section
        pdf.text "MEDICAL CONSULTATION REPORT", size: 18, align: :center, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 20
        
        # Patient Information section
        pdf.text "PATIENT INFORMATION", size: 14, style: :bold, color: "333333"
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        
        patient = report.consultation.patient
        pdf.text "Patient Name: #{patient.firstname} #{patient.lastname}", size: 12
        pdf.text "Date of Consultation: #{report.consultation.created_at.strftime("%B %d, %Y")}", size: 12
        pdf.text "Patient ID: #{patient.id}", size: 12
        pdf.move_down 15
        
        # Clinical Details section
        pdf.text "CLINICAL DETAILS", size: 14, style: :bold, color: "333333"
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        
        pdf.text "Primary Diagnosis:", size: 12, style: :bold
        pdf.text report.diagnosis, size: 12
        pdf.move_down 8
        
        pdf.text "Recommended Procedures:", size: 12, style: :bold
        pdf.text report.procedures, size: 12
        pdf.move_down 8
        
        pdf.text "Prescription:", size: 12, style: :bold
        pdf.text report.prescription, size: 12
        pdf.move_down 8
        
        pdf.text "Physician Notes:", size: 12, style: :bold
        pdf.text report.doctor_notes, size: 12
        pdf.move_down 20
        
        # Clinical Images section
        if report.images.any?
          pdf.text "CLINICAL IMAGES", size: 14, style: :bold, color: "333333"
          pdf.stroke_horizontal_rule
          pdf.move_down 15
          
          images_per_line = 2 # More professional with 2 images per line
          image_width = (pdf.bounds.width - (images_per_line - 1) * 20) / images_per_line
          image_height = 180
          
          report.images.each_with_index do |image, index|
            if index % images_per_line == 0 && index != 0
              pdf.move_down image_height + 20
            end
            
            begin
              tempfile = Tempfile.new(['report_image', '.jpg'], binmode: true)
              tempfile.write(image.download)
              tempfile.rewind
              
              x_position = (index % images_per_line) * (image_width + 20)
              
              # Image with border and label
              pdf.bounding_box([x_position, pdf.cursor], width: image_width) do
                pdf.image tempfile.path, fit: [image_width, image_height]
                pdf.stroke_bounds
                pdf.move_down 5
                pdf.text "Image #{index + 1}", size: 8, align: :center
              end
              
              tempfile.close
              tempfile.unlink
            rescue => e
              pdf.text "Error loading image: #{e.message}", size: 10, color: "FF0000"
            end
          end
          pdf.move_down 30
        end
        
        # Footer
        pdf.stroke_horizontal_rule
        pdf.move_down 15
        pdf.text "This report was generated by DermaPro Medical Platform", size: 10, align: :center
        pdf.text "For any questions, please contact support@dermapro.com", size: 10, align: :center
        pdf.text "© #{Time.now.year} DermaPro. All rights reserved.", size: 10, align: :center
        
        # Add page numbers
        pdf.number_pages "<page> of <total>", {
          start_count_at: 1,
          page_filter: :all,
          align: :right,
          size: 10,
          at: [pdf.bounds.right - 50, 0]
        }
      end
    end   
  end
  