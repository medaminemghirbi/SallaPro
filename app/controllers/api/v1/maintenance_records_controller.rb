# frozen_string_literal: true

module Api
  module V1
    class MaintenanceRecordsController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_material
      before_action :set_maintenance_record, only: [:show, :update, :destroy, :complete, :cancel]

      # GET /api/v1/companies/:company_id/materials/:material_id/maintenance_records
      def index
        @records = @material.maintenance_records
                            .includes(:performed_by)
                            .by_type(params[:maintenance_type])
                            .by_status(params[:status])
                            .recent

        render json: @records, each_serializer: MaintenanceRecordSerializer, status: :ok
      end

      # GET /api/v1/companies/:company_id/materials/:material_id/maintenance_records/:id
      def show
        render json: @record, serializer: MaintenanceRecordSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/materials/:material_id/maintenance_records
      def create
        @record = @material.maintenance_records.build(maintenance_record_params)
        @record.performed_by = current_user if @record.performed_by_id.blank?

        if @record.save
          render json: {
            message: 'Maintenance record created successfully',
            maintenance_record: MaintenanceRecordSerializer.new(@record)
          }, status: :created
        else
          render json: {
            error: 'Failed to create maintenance record',
            details: @record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/companies/:company_id/materials/:material_id/maintenance_records/:id
      def update
        if @record.update(maintenance_record_params)
          render json: {
            message: 'Maintenance record updated successfully',
            maintenance_record: MaintenanceRecordSerializer.new(@record)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update maintenance record',
            details: @record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/materials/:material_id/maintenance_records/:id
      def destroy
        if @record.destroy
          render json: { message: 'Maintenance record deleted successfully' }, status: :ok
        else
          render json: {
            error: 'Failed to delete maintenance record',
            details: @record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/materials/:material_id/maintenance_records/:id/complete
      def complete
        @record.status = 'completed'
        @record.completed_date = Date.current
        @record.performed_by = current_user if @record.performed_by_id.blank?

        if @record.save
          render json: {
            message: 'Maintenance completed successfully',
            maintenance_record: MaintenanceRecordSerializer.new(@record)
          }, status: :ok
        else
          render json: {
            error: 'Failed to complete maintenance',
            details: @record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/materials/:material_id/maintenance_records/:id/cancel
      def cancel
        if @record.update(status: 'cancelled')
          render json: {
            message: 'Maintenance cancelled',
            maintenance_record: MaintenanceRecordSerializer.new(@record)
          }, status: :ok
        else
          render json: {
            error: 'Failed to cancel maintenance',
            details: @record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Company not found' }, status: :not_found
      end

      def set_material
        @material = @company.materials.find(params[:material_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Material not found' }, status: :not_found
      end

      def set_maintenance_record
        @record = @material.maintenance_records.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Maintenance record not found' }, status: :not_found
      end

      def maintenance_record_params
        params.permit(:maintenance_type, :status, :scheduled_date, :completed_date,
                      :description, :notes, :cost, :service_provider, :duration_hours,
                      :performed_by_id, parts_replaced: [])
      end
    end
  end
end
