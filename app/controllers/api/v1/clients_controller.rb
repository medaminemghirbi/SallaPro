# frozen_string_literal: true

module Api
  module V1
    class ClientsController < ApplicationController
      before_action :authorize_request
      before_action :set_client, only: [:show, :update, :destroy]

      # GET /api/v1/clients
      def index
        @clients = ClientFilterService.call(Client.all, filter_params)

        render json: @clients, each_serializer: ClientSerializer, status: :ok
      end

      # POST /api/v1/clients
      def create
        ActiveRecord::Base.transaction do
          client = User.create!(client_params.merge(type: 'Client'))
          client.skip_confirmation!

          attach_avatar(client) if params[:avatar].present?

          render json: { client: client }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      # POST /api/v1/clients/export
      def export
        clients = ClientFilterService.call(Client.all, export_filter_params)
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

            def update
        # Only allow updating specific fields
        update_params = params.require(:client).permit(:address, :phone_number)
        
        if @client.update(update_params)
          render json: {
            message: 'Client updated successfully',
            client: @client
          }, status: :ok
        else
          render json: {
            error: 'Failed to update client',
            details: @client.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/clients/:id
      # Delete a client by ID
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

      def filter_params
        {
          search: params[:search],
          resourceType: params[:resourceType],
          resource_type: params[:resource_type]
        }.compact
      end

      def export_filter_params
        {
          clientIds: params[:clientIds],
          client_ids: params[:client_ids],
          filters: params[:filters]
        }.compact
      end

      def attach_avatar(client)
        client.avatar.attach(params[:avatar])
      end
    end
  end
end
