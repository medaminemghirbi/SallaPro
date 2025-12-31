class Api::V1::ClientsController < ApplicationController
    before_action :authorize_request
    before_action :set_client, only: [:show, :update, :destroy]
    def index
        clients = Client.all
        # Render JSON using ActiveModel::Serializer
        render json: clients, each_serializer: ClientSerializer
    end

    def create
    ActiveRecord::Base.transaction do
        # 1️⃣ Permitted params
        client_params = params.permit(
        :firstname, :lastname, :email, :password, :password_confirmation,
        :birthday, :address, :phone_number
        )

        # 2️⃣ Create the client user
        client = User.create!(client_params.merge(type: "Client"))
        client.skip_confirmation! 

        # 3️⃣ Optional: attach default avatar if needed
        if params[:avatar].present?
        client.avatar.attach(params[:avatar])
        end

        # 4️⃣ Return JSON
        render json: { client: client }, status: :created
    end
    rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages.first }, status: :unprocessable_entity
    end
end
