# frozen_string_literal: true

module Api
  module V1
    class CompanyDocumentsController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_document, only: [:show, :update, :destroy, :download]

      # GET /api/v1/companies/:company_id/documents
      def index
        @documents = @company.company_documents
                             .includes(:uploaded_by)
                             .search_by_name(params[:search])
                             .by_type(params[:document_type])
                             .by_category(params[:category])
                             .recent

        # Apply pagination if needed
        if params[:page].present?
          @documents = @documents.page(params[:page]).per(params[:per_page] || 10)
          render json: {
            documents: ActiveModelSerializers::SerializableResource.new(@documents, each_serializer: CompanyDocumentSerializer),
            meta: {
              current_page: @documents.current_page,
              total_pages: @documents.total_pages,
              total_count: @documents.total_count
            }
          }, status: :ok
        else
          render json: @documents, each_serializer: CompanyDocumentSerializer, status: :ok
        end
      end

      # GET /api/v1/companies/:company_id/documents/:id
      def show
        render json: @document, serializer: CompanyDocumentSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/documents
      def create
        @document = @company.company_documents.build(document_params)
        @document.uploaded_by = current_user

        if @document.save
          render json: {
            message: 'Document uploaded successfully',
            document: CompanyDocumentSerializer.new(@document)
          }, status: :created
        else
          render json: {
            error: 'Failed to upload document',
            details: @document.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/companies/:company_id/documents/:id
      def update
        if @document.update(document_update_params)
          render json: {
            message: 'Document updated successfully',
            document: CompanyDocumentSerializer.new(@document)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update document',
            details: @document.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/documents/:id
      def destroy
        if @document.destroy
          render json: { message: 'Document deleted successfully' }, status: :ok
        else
          render json: {
            error: 'Failed to delete document',
            details: @document.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/documents/:id/download
      def download
        if @document.file.attached?
          redirect_to rails_blob_url(@document.file, disposition: 'attachment')
        else
          render json: { error: 'File not found' }, status: :not_found
        end
      end

      # DELETE /api/v1/companies/:company_id/documents/bulk_delete
      def bulk_delete
        document_ids = params[:document_ids]
        
        if document_ids.blank?
          render json: { error: 'No document IDs provided' }, status: :bad_request
          return
        end

        documents = @company.company_documents.where(id: document_ids)
        deleted_count = documents.destroy_all.count

        render json: {
          message: "#{deleted_count} document(s) deleted successfully",
          deleted_count: deleted_count
        }, status: :ok
      end

      # GET /api/v1/companies/:company_id/documents/categories
      def categories
        categories = @company.company_documents.distinct.pluck(:category).compact
        render json: { categories: categories }, status: :ok
      end

      # GET /api/v1/companies/:company_id/documents/document_types
      def document_types
        render json: { document_types: CompanyDocument::DOCUMENT_TYPES }, status: :ok
      end

      # GET /api/v1/companies/:company_id/documents/stats
      def stats
        total = @company.company_documents.count
        by_type = @company.company_documents.group(:document_type).count
        total_size = @company.company_documents.sum(:file_size)
        recent_uploads = @company.company_documents.where('created_at > ?', 30.days.ago).count

        render json: {
          total_documents: total,
          by_type: by_type,
          total_size: total_size,
          total_size_formatted: format_file_size(total_size),
          recent_uploads_30_days: recent_uploads
        }, status: :ok
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Company not found' }, status: :not_found
      end

      def set_document
        @document = @company.company_documents.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Document not found' }, status: :not_found
      end

      def document_params
        params.permit(:name, :description, :document_type, :category,
                      :is_public, :expires_at, :file, metadata: {})
      end

      def document_update_params
        params.permit(:name, :description, :document_type, :category,
                      :is_public, :expires_at, :file, metadata: {})
      end

      def format_file_size(size)
        return '0 B' if size.nil? || size.zero?

        if size < 1024
          "#{size} B"
        elsif size < 1024 * 1024
          "#{(size / 1024.0).round(2)} KB"
        elsif size < 1024 * 1024 * 1024
          "#{(size / (1024.0 * 1024.0)).round(2)} MB"
        else
          "#{(size / (1024.0 * 1024.0 * 1024.0)).round(2)} GB"
        end
      end
    end
  end
end
