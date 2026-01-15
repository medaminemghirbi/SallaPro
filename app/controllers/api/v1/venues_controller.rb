# frozen_string_literal: true

module Api
  module V1
    class VenuesController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_venue, only: [:show, :update, :destroy]

      # GET /api/v1/companies/:company_id/venues
      def index
        @venues = @company.venues
        @venues = @venues.search_by_term(params[:search]) if params[:search].present?
        @venues = @venues.by_type(params[:venue_type]) if params[:venue_type].present?
        @venues = @venues.where(status: params[:status]) if params[:status].present?
        @venues = @venues.by_capacity(params[:capacity_min], params[:capacity_max]) if params[:capacity_min].present?
        @venues = @venues.indoor if params[:is_indoor] == 'true'
        @venues = @venues.outdoor if params[:is_outdoor] == 'true'
        @venues = @venues.order(created_at: :desc)

        if params[:page].present?
          @venues = @venues.page(params[:page]).per(params[:per_page] || 10)
          render json: {
            venues: ActiveModelSerializers::SerializableResource.new(@venues, each_serializer: VenueSerializer),
            meta: {
              current_page: @venues.current_page,
              total_pages: @venues.total_pages,
              total_count: @venues.total_count
            }
          }, status: :ok
        else
          render json: @venues, each_serializer: VenueSerializer, status: :ok
        end
      end

      # GET /api/v1/companies/:company_id/venues/:id
      def show
        render json: @venue, serializer: VenueSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/venues
      def create
        @venue = @company.venues.build(venue_params)

        if @venue.save
          attach_images if params[:images].present?
          render json: {
            message: 'Venue created successfully',
            venue: VenueSerializer.new(@venue)
          }, status: :created
        else
          render json: {
            error: 'Failed to create venue',
            details: @venue.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/companies/:company_id/venues/:id
      def update
        if @venue.update(venue_params)
          attach_images if params[:images].present?
          render json: {
            message: 'Venue updated successfully',
            venue: VenueSerializer.new(@venue)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update venue',
            details: @venue.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/venues/:id
      def destroy
        if @venue.destroy
          render json: { message: 'Venue deleted successfully' }, status: :ok
        else
          render json: {
            error: 'Failed to delete venue',
            details: @venue.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/venues/types
      def types
        venue_types = Venue::VENUE_TYPES.map do |key, label|
          { value: key, label: label, count: @company.venues.where(venue_type: key).count }
        end
        render json: { types: venue_types }, status: :ok
      end

      # GET /api/v1/companies/:company_id/venues/stats
      def stats
        total = @company.venues.count
        by_status = @company.venues.group(:status).count
        by_type = @company.venues.group(:venue_type).count
        indoor_count = @company.venues.indoor.count
        outdoor_count = @company.venues.outdoor.count
        available_count = @company.venues.available.count
        total_capacity = @company.venues.sum(:capacity_max)
        avg_hourly_rate = @company.venues.average(:hourly_rate)&.round(2)
        avg_daily_rate = @company.venues.average(:daily_rate)&.round(2)

        render json: {
          total_venues: total,
          by_status: by_status,
          by_type: by_type,
          indoor_count: indoor_count,
          outdoor_count: outdoor_count,
          available_count: available_count,
          total_capacity: total_capacity,
          average_hourly_rate: avg_hourly_rate,
          average_daily_rate: avg_daily_rate
        }, status: :ok
      end

      # GET /api/v1/companies/:company_id/venues/available
      def available
        @venues = @company.venues.available.order(created_at: :desc)
        render json: @venues, each_serializer: VenueSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/venues/export
      def export
        venues = @company.venues
        venues = venues.search_by_term(params.dig(:filters, :search)) if params.dig(:filters, :search).present?
        venues = venues.by_type(params.dig(:filters, :venue_type)) if params.dig(:filters, :venue_type).present?
        venues = venues.where(status: params.dig(:filters, :status)) if params.dig(:filters, :status).present?

        # Filter by IDs if provided
        if params[:venueIds].present? && params[:venueIds].is_a?(Array) && params[:venueIds].any?
          venues = venues.where(id: params[:venueIds])
        end

        result = VenueExportService.call(venues, params[:format])

        if result[:error]
          render json: { error: result[:error] }, status: result[:status]
        else
          send_data result[:data],
                    filename: result[:filename],
                    type: result[:type],
                    disposition: 'attachment'
        end
      end

      # DELETE /api/v1/companies/:company_id/venues/:id/images/:image_id
      def destroy_image
        @venue = @company.venues.find(params[:id])
        image = @venue.images.find(params[:image_id])
        image.purge

        render json: { message: 'Image deleted successfully' }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Image not found' }, status: :not_found
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Company not found' }, status: :not_found
      end

      def set_venue
        @venue = @company.venues.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Venue not found' }, status: :not_found
      end

      def venue_params
        params.permit(
          :name, :description, :venue_type, :capacity_min, :capacity_max,
          :surface_area, :hourly_rate, :daily_rate, :weekend_rate,
          :location, :floor, :is_indoor, :is_outdoor,
          :has_catering, :has_parking, :parking_capacity,
          :has_sound_system, :has_lighting, :has_air_conditioning, :has_stage,
          :status, amenities: []
        )
      end

      def attach_images
        if params[:images].is_a?(Array)
          params[:images].each do |image|
            @venue.images.attach(image)
          end
        else
          @venue.images.attach(params[:images])
        end
      end
    end
  end
end
