# frozen_string_literal: true

module Api
  module V1
    class VenueContractsController < ApplicationController
      before_action :authorize_request
      before_action :set_company
      before_action :set_contract, only: [:show, :update, :destroy, :convert_to_devis, :convert_to_contract, :sign, :generate_pdf]

      # GET /api/v1/companies/:company_id/venue_contracts
      def index
        @contracts = @company.venue_contracts.includes(:venue, :client, :created_by)
        
        # Filters
        @contracts = @contracts.search_by_term(params[:search]) if params[:search].present?
        @contracts = @contracts.by_venue(params[:venue_id]) if params[:venue_id].present?
        @contracts = @contracts.by_client(params[:client_id]) if params[:client_id].present?
        @contracts = @contracts.by_status(params[:status]) if params[:status].present?
        
        # Date filters
        if params[:from_date].present?
          @contracts = @contracts.where('event_start_date >= ?', params[:from_date])
        end
        if params[:to_date].present?
          @contracts = @contracts.where('event_start_date <= ?', params[:to_date])
        end

        @contracts = @contracts.recent

        render json: @contracts, each_serializer: VenueContractSerializer, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_contracts/:id
      def show
        render json: @contract, serializer: VenueContractSerializer, status: :ok
      end

      # POST /api/v1/companies/:company_id/venue_contracts
      def create
        @contract = @company.venue_contracts.build(contract_params)
        @contract.created_by = current_user

        if @contract.save
          render json: @contract, serializer: VenueContractSerializer, status: :created
        else
          render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/companies/:company_id/venue_contracts/:id
      def update
        if @contract.update(contract_params)
          render json: @contract, serializer: VenueContractSerializer, status: :ok
        else
          render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/companies/:company_id/venue_contracts/:id
      def destroy
        if @contract.destroy
          render json: { message: 'Contrat supprimé avec succès' }, status: :ok
        else
          render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/venue_contracts/:id/convert_to_devis
      def convert_to_devis
        if @contract.convert_to_devis!
          render json: @contract, serializer: VenueContractSerializer, status: :ok
        else
          render json: { error: 'Impossible de convertir en devis' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/venue_contracts/:id/convert_to_contract
      def convert_to_contract
        if @contract.convert_to_contract!
          render json: @contract, serializer: VenueContractSerializer, status: :ok
        else
          render json: { error: 'Impossible de convertir en contrat' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/companies/:company_id/venue_contracts/:id/sign
      def sign
        signed_pdf = params[:signed_document]
        
        if @contract.sign!(signed_pdf)
          render json: @contract.reload, serializer: VenueContractSerializer, status: :ok
        else
          render json: { error: 'Impossible de signer le contrat' }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/venue_contracts/:id/generate_pdf
      def generate_pdf
        pdf_data = VenueContractPdfService.new(@contract).generate

        send_data pdf_data,
                  filename: "#{@contract.status == 'devis' ? 'Devis' : 'Contrat'}_#{@contract.contract_number}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end

      # GET /api/v1/companies/:company_id/venue_contracts/stats
      def stats
        contracts = @company.venue_contracts

        stats = {
          total: contracts.count,
          by_status: {
            draft: contracts.drafts.count,
            devis: contracts.devis.count,
            contract: contracts.contracts.count,
            signed: contracts.signed.count,
            cancelled: contracts.cancelled.count
          },
          total_amount: contracts.active.sum(:total_amount) || 0,
          total_paid: contracts.active.sum(:amount_paid) || 0,
          pending_amount: (contracts.active.sum(:total_amount) || 0) - (contracts.active.sum(:amount_paid) || 0),
          this_month: contracts.where('created_at >= ?', Time.current.beginning_of_month).count,
          upcoming_events: contracts.active.upcoming.count
        }

        render json: stats, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_contracts/status_options
      def status_options
        render json: VenueContract::STATUS_OPTIONS.map { |k, v| { value: k, label: v } }, status: :ok
      end

      # GET /api/v1/companies/:company_id/venue_contracts/event_types
      def event_types
        render json: VenueContract::EVENT_TYPES.map { |k, v| { value: k, label: v } }, status: :ok
      end

      private

      def set_company
        @company = Company.find(params[:company_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Entreprise non trouvée' }, status: :not_found
      end

      def set_contract
        @contract = @company.venue_contracts.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Contrat non trouvé' }, status: :not_found
      end

      def contract_params
        params.require(:venue_contract).permit(
          :venue_id, :client_id, :title, :description, :status,
          :event_type, :expected_guests, :event_start_date, :event_end_date,
          :base_price, :discount_percent, :discount_amount, :tax_rate,
          :deposit_amount, :deposit_paid, :deposit_paid_at,
          :payment_method, :payment_status, :amount_paid,
          :valid_until, :special_requests, :terms_and_conditions, :internal_notes,
          selected_options: [], additional_services: []
        )
      end
    end
  end
end
