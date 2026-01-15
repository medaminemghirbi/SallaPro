# frozen_string_literal: true

module Api
  module V1
    class VenueReservationsController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_reservation, only: [:show, :update, :destroy, :cancel, :complete]

      # GET /api/v1/companies/:company_id/venue_reservations
      def index
        @reservations = @company.venue_reservations.includes(:venue, :client, :venue_contract)
        
        # Filters
        @reservations = @reservations.search_by_term(params[:search]) if params[:search].present?
        @reservations = @reservations.by_venue(params[:venue_id]) if params[:venue_id].present?
        @reservations = @reservations.by_client(params[:client_id]) if params[:client_id].present?
        @reservations = @reservations.by_status(params[:status]) if params[:status].present?
        
        # Date filters
        if params[:from_date].present?
          @reservations = @reservations.where('start_date >= ?', params[:from_date])
        end
        if params[:to_date].present?
          @reservations = @reservations.where('start_date <= ?', params[:to_date])
        end

        # Period filter
        case params[:period]
        when 'upcoming'
          @reservations = @reservations.upcoming
        when 'current'
          @reservations = @reservations.current
        when 'past'
          @reservations = @reservations.past
        else
          @reservations = @reservations.recent
        end

        render json: @reservations, each_serializer: VenueReservationSerializer, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_reservations/:id
      def show
        render json: @reservation, serializer: VenueReservationSerializer, status: :ok
      end

      # PUT /api/v1/companies/:company_id/venue_reservations/:id
      def update
        if @reservation.update(reservation_params)
          render json: @reservation, serializer: VenueReservationSerializer, status: :ok
        else
          render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/venue_reservations/:id
      def destroy
        if @reservation.destroy
          render json: { message: 'Réservation supprimée avec succès' }, status: :ok
        else
          render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/venue_reservations/:id/cancel
      def cancel
        if @reservation.cancel!
          render json: @reservation, serializer: VenueReservationSerializer, status: :ok
        else
          render json: { error: 'Impossible d\'annuler la réservation' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/venue_reservations/:id/complete
      def complete
        if @reservation.complete!
          render json: @reservation, serializer: VenueReservationSerializer, status: :ok
        else
          render json: { error: 'Impossible de marquer comme terminée' }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/venue_reservations/stats
      def stats
        reservations = @company.venue_reservations

        stats = {
          total: reservations.count,
          by_status: {
            confirmed: reservations.confirmed.count,
            in_progress: reservations.in_progress.count,
            completed: reservations.completed.count,
            cancelled: reservations.cancelled.count
          },
          upcoming: reservations.upcoming.count,
          current: reservations.current.count,
          total_revenue: reservations.active.sum(:total_amount) || 0,
          total_collected: reservations.active.sum(:amount_paid) || 0,
          this_month: reservations.where('created_at >= ?', Time.current.beginning_of_month).count
        }

        render json: stats, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_reservations/calendar
      def calendar
        start_date = params[:start] ? Date.parse(params[:start]) : Date.current.beginning_of_month
        end_date = params[:end] ? Date.parse(params[:end]) : Date.current.end_of_month

        reservations = @company.venue_reservations
                               .active
                               .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                               .includes(:venue, :client)

        events = reservations.map do |r|
          {
            id: r.id,
            title: "#{r.venue_name} - #{r.client_name}",
            start: r.start_date.iso8601,
            end: r.end_date.iso8601,
            venue_id: r.venue_id,
            venue_name: r.venue_name,
            client_name: r.client_name,
            status: r.status,
            color: reservation_color(r.status)
          }
        end

        render json: events, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_reservations/check_availability
      def check_availability
        venue_id = params[:venue_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        return render json: { error: 'Paramètres manquants' }, status: :bad_request unless venue_id && start_date && end_date

        overlapping = VenueReservation.active
                                       .by_venue(venue_id)
                                       .in_date_range(DateTime.parse(start_date), DateTime.parse(end_date))

        render json: {
          available: overlapping.empty?,
          conflicts: overlapping.map { |r| { id: r.id, start: r.start_date, end: r.end_date, client: r.client_name } }
        }, status: :ok
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Entreprise non trouvée' }, status: :not_found
      end

      def set_reservation
        @reservation = @company.venue_reservations.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Réservation non trouvée' }, status: :not_found
      end

      def reservation_params
        params.require(:venue_reservation).permit(
          :status, :payment_status, :amount_paid, :notes, metadata: {}
        )
      end

      def reservation_color(status)
        case status
        when 'confirmed' then '#22c55e'
        when 'in_progress' then '#3b82f6'
        when 'completed' then '#6b7280'
        when 'cancelled' then '#ef4444'
        else '#8b5cf6'
        end
      end
    end
  end
end
