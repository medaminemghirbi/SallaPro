class Api::V1::DocumentsController < ApplicationController


  def create
    document = Document.new(document_params)

    if document.save
      # Use document_data method to include file_type and document_url
      render json: { message: 'Document uploaded successfully', document: document_data(document) }, status: :created, methods: [:document_url]
    else
      render json: { errors: document.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def show
    doctor = Doctor.find(params[:id])

    documents = Document.current.where(doctor_id: doctor.id).all
    # Use document_data method to include file_type and document_url
    render json: documents.map { |doc| document_data(doc) }, status: :ok, methods: [:document_url]
  end

  def destroy 
    document = Document.find(params[:id])
    if document.update(is_archived: true)
      render json: { message: 'Document uploaded successfully', document: document_data(document) }, status: :created, methods: [:document_url]
    else
    render json: { errors: document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def download
    doc = Document.find params[:id]
  
    begin
      data = URI.open(doc.document_url)
      send_data data.read, filename: doc.title, type: doc.file.content_type, disposition: 'attachment'
    rescue OpenURI::HTTPError
      render body: nil, status: :forbidden
    end
  end
  
  def delete_all_documents
    doctor = Doctor.find(params[:id])
    if doctor 
      Document.where(doctor_id: doctor.id).update(is_archived: true)
      render json: { message: 'All Documents deleted successfully'}
    else
    render json: { errors: doctor.errors.full_messages }, status: :unprocessable_entity
    end

  end

  def update
    doc = Document.find params[:id]
    if doc.update(document_params)
      render json: doc
    else
      render json: doc.errors, status: :unprocessable_entity
    end
  end

  private

  def document_params
    params.require(:document).permit(:title, :file, :doctor_id)
  end

  # Method to format document data including file_type and document_url
  def document_data(doc)
    {
      id: doc.id,
      title: doc.title,
      file_type: doc.file.attached? ? doc.file.content_type : nil,  # Include file type
      size: doc.file.attached? ? (doc.file.blob.byte_size.to_f / 1_024).round(2) : 0,  # Convert size to KB

      document_url: doc.file.attached? ? url_for(doc.file) : nil    # Include document URL
    }
  end
end
