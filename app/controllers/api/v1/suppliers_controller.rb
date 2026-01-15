# frozen_string_literal: true

module Api
  module V1
    class SuppliersController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_supplier, only: [:show, :update, :destroy]

      # GET /api/v1/companies/:company_id/suppliers
      def index
        @suppliers = @company.suppliers
        @suppliers = @suppliers.search_by_term(params[:search]) if params[:search].present?
        @suppliers = @suppliers.by_category(params[:category]) if params[:category].present?
        @suppliers = @suppliers.by_status(params[:status]) if params[:status].present?

        render json: @suppliers, each_serializer: SupplierSerializer, status: :ok
      end

      # GET /api/v1/companies/:company_id/suppliers/:id
      def show
        render json: @supplier, serializer: SupplierSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/suppliers
      def create
        @supplier = @company.suppliers.build(supplier_params)

        if @supplier.save
          attach_logo if params[:logo].present?
          render json: @supplier, serializer: SupplierSerializer, status: :created
        else
          render json: { errors: @supplier.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/companies/:company_id/suppliers/:id
      def update
        if @supplier.update(supplier_params)
          attach_logo if params[:logo].present?
          render json: @supplier, serializer: SupplierSerializer, status: :ok
        else
          render json: { errors: @supplier.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/suppliers/:id
      def destroy
        if @supplier.destroy
          render json: { message: 'Supplier deleted successfully' }, status: :ok
        else
          render json: { errors: @supplier.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/suppliers/export
      def export
        suppliers = @company.suppliers
        suppliers = suppliers.search_by_term(params[:search]) if params[:search].present?
        suppliers = suppliers.by_category(params[:category]) if params[:category].present?
        suppliers = suppliers.by_status(params[:status]) if params[:status].present?

        # Filter by IDs if provided
        if params[:supplierIds].present? && params[:supplierIds].is_a?(Array) && params[:supplierIds].any?
          suppliers = suppliers.where(id: params[:supplierIds])
        end

        result = SupplierExportService.call(suppliers, params[:format])

        if result[:error]
          render json: { error: result[:error] }, status: result[:status]
        else
          send_data result[:data],
                    filename: result[:filename],
                    type: result[:type],
                    disposition: 'attachment'
        end
      end

      # GET /api/v1/companies/:company_id/suppliers/categories
      def categories
        categories = @company.suppliers.distinct.pluck(:category).compact.sort
        render json: categories, status: :ok
      end

      # GET /api/v1/companies/:company_id/suppliers/stats
      def stats
        stats = {
          total: @company.suppliers.count,
          active: @company.suppliers.active.count,
          inactive: @company.suppliers.inactive.count,
          suspended: @company.suppliers.suspended.count,
          by_category: @company.suppliers.group(:category).count
        }
        render json: stats, status: :ok
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Company not found' }, status: :not_found
      end

      def set_supplier
        @supplier = @company.suppliers.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Supplier not found' }, status: :not_found
      end

      def supplier_params
        params.permit(
          :name, :email, :phone_number, :address, :city, :country, :postal_code,
          :contact_person, :contact_email, :contact_phone, :website, :tax_id,
          :category, :description, :notes, :payment_terms, :status,
          :latitude, :longitude
        )
      end

      def attach_logo
        @supplier.logo.attach(params[:logo])
      end
    end
  end
end
