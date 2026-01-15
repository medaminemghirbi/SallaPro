# frozen_string_literal: true

module Api
  module V1
    class MaterialsController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_material, only: [:show, :update, :destroy]

      # GET /api/v1/companies/:company_id/materials
      def index
        @materials = @company.materials
                             .includes(:assigned_to)
                             .search_by_name(params[:search])
                             .by_status(params[:status])
                             .by_category(params[:category])
                             .recent

        if params[:page].present?
          @materials = @materials.page(params[:page]).per(params[:per_page] || 10)
          render json: {
            materials: ActiveModelSerializers::SerializableResource.new(@materials, each_serializer: MaterialSerializer),
            meta: {
              current_page: @materials.current_page,
              total_pages: @materials.total_pages,
              total_count: @materials.total_count
            }
          }, status: :ok
        else
          render json: @materials, each_serializer: MaterialSerializer, status: :ok
        end
      end

      # GET /api/v1/companies/:company_id/materials/:id
      def show
        render json: @material, serializer: MaterialSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/materials
      def create
        @material = @company.materials.build(material_params)

        if @material.save
          render json: {
            message: 'Material created successfully',
            material: MaterialSerializer.new(@material)
          }, status: :created
        else
          render json: {
            error: 'Failed to create material',
            details: @material.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/companies/:company_id/materials/:id
      def update
        if @material.update(material_params)
          render json: {
            message: 'Material updated successfully',
            material: MaterialSerializer.new(@material)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update material',
            details: @material.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/materials/:id
      def destroy
        if @material.destroy
          render json: { message: 'Material deleted successfully' }, status: :ok
        else
          render json: {
            error: 'Failed to delete material',
            details: @material.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/materials/categories
      def categories
        categories = @company.materials.distinct.pluck(:category).compact
        render json: { categories: categories }, status: :ok
      end

      # GET /api/v1/companies/:company_id/materials/stats
      def stats
        total = @company.materials.count
        by_status = @company.materials.group(:status).count
        needs_maintenance = @company.materials.needs_maintenance.count
        warranty_expiring = @company.materials.warranty_expiring_soon.count
        warranty_expired = @company.materials.warranty_expired.count

        render json: {
          total_materials: total,
          by_status: by_status,
          needs_maintenance: needs_maintenance,
          warranty_expiring_soon: warranty_expiring,
          warranty_expired: warranty_expired
        }, status: :ok
      end

      # GET /api/v1/companies/:company_id/materials/alerts
      def alerts
        needs_maintenance = @company.materials.needs_maintenance.recent
        warranty_expiring = @company.materials.warranty_expiring_soon.recent
        overdue_maintenance = @company.materials.where('next_maintenance_date < ?', Date.current)

        render json: {
          needs_maintenance: ActiveModelSerializers::SerializableResource.new(needs_maintenance, each_serializer: MaterialSerializer),
          warranty_expiring: ActiveModelSerializers::SerializableResource.new(warranty_expiring, each_serializer: MaterialSerializer),
          overdue_maintenance: ActiveModelSerializers::SerializableResource.new(overdue_maintenance, each_serializer: MaterialSerializer)
        }, status: :ok
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Company not found' }, status: :not_found
      end

      def set_material
        @material = @company.materials.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Material not found' }, status: :not_found
      end

      def material_params
        params.permit(:name, :description, :serial_number, :model, :brand, :category,
                      :status, :location, :purchase_price, :purchase_date,
                      :warranty_expiry_date, :next_maintenance_date, :maintenance_interval_days,
                      :assigned_to_id, :image, metadata: {})
      end
    end
  end
end
