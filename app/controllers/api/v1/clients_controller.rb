# frozen_string_literal: true

module Api
  module V1
    class ClientsController < ApplicationController
      before_action :authorize_request
      before_action :set_client, only: [:show, :update, :destroy]

      # GET /api/v1/clients
      def index
        @clients = Client.where(company_id: current_user.company_id)
        @clients = @clients.search_by_term(params[:search]) if params[:search].present?
        @clients = @clients.by_status(params[:status]) if params[:status].present?
        @clients = @clients.by_country(params[:country]) if params[:country].present?
        @clients = @clients.recent

        render json: @clients, each_serializer: ClientSerializer, status: :ok
      end

      # GET /api/v1/clients/:id
      def show
        render json: @client, serializer: ClientSerializer, status: :ok
      end

      # POST /api/v1/clients
      def create
        ActiveRecord::Base.transaction do
          client = User.create!(client_params.merge(type: 'Client', status: 'active'))
          client.skip_confirmation!

          attach_avatar(client) if params[:avatar].present?

          render json: { client: ClientSerializer.new(client) }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      # POST /api/v1/clients/export
      def export
        clients = Client.all
        clients = clients.search_by_term(params.dig(:filters, :search)) if params.dig(:filters, :search).present?
        clients = clients.by_status(params.dig(:filters, :status)) if params.dig(:filters, :status).present?
        
        # Filter by IDs if provided
        if params[:clientIds].present? && params[:clientIds].is_a?(Array) && params[:clientIds].any?
          clients = clients.where(id: params[:clientIds])
        end

        result = ClientExportService.call(clients, params[:format])

        if result[:error]
          render json: { error: result[:error] }, status: result[:status]
        else
          send_data result[:data],
                    filename: result[:filename],
                    type: result[:type],
                    disposition: 'attachment'
        end
      end

      # PUT /api/v1/clients/:id
      def update
        update_params = params.require(:client).permit(
          :firstname, :lastname, :email, :phone_number, :address,
          :birthday, :country, :latitude, :longitude, :status
        )
        
        if @client.update(update_params)
          render json: {
            message: 'Client updated successfully',
            client: ClientSerializer.new(@client)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update client',
            details: @client.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/clients/:id
      def destroy
        if @client.destroy
          render json: {
            message: 'Client deleted successfully'
          }, status: :ok
        else
          render json: {
            error: 'Failed to delete client',
            details: @client.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/clients/stats
      def stats
        stats = {
          total: Client.count,
          active: Client.active.count,
          inactive: Client.inactive.count,
          blocked: Client.blocked.count,
          by_country: Client.group(:country).count,
          recent_30_days: Client.where('created_at >= ?', 30.days.ago).count
        }
        render json: stats, status: :ok
      end

      # GET /api/v1/clients/countries
      def countries
        countries = Client.distinct.pluck(:country).compact.sort
        render json: countries, status: :ok
      end

      private

      def set_client
        @client = Client.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Client not found' }, status: :not_found
      end

      def client_params
        params.permit(
          :firstname, :lastname, :email, :password, :password_confirmation,
          :birthday, :address, :latitude, :longitude, :phone_number, :country
        )
      end

      def attach_avatar(client)
        client.avatar.attach(params[:avatar])
      end
    end
  end
end
