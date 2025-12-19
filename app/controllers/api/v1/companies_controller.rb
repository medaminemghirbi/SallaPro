class Api::V1::CompaniesController < ApplicationController
  before_action :authorize_request

  def index
    # Eager load admin and company_type to avoid N+1 queries
    companies = Company.includes(:admin, :company_type).all

    # Render JSON using ActiveModel::Serializer
    render json: companies, each_serializer: CompanySerializer
  end

    def create
    ActiveRecord::Base.transaction do
      # 1️⃣ Create the admin user
      admin_params = params.permit(:firstname, :lastname, :email, :password, :password_confirmation)
      admin = User.new(admin_params.merge(type: "Admin"))
      admin.save!

      # 2️⃣ Create the company linked to this admin
      company_params = params.permit(:company_name, :company_type_id, :billing_address, :description)
      company = Company.new(
        name: company_params[:company_name],
        company_type_id: company_params[:company_type_id],
        billing_address: company_params[:billing_address] || admin.email,
        description: company_params[:description],
        user_id: admin.id
      )
      company.save!

      # 3️⃣ Return JSON of both
      render json: {
        admin: AdminSerializer.new(admin),
        company: CompanySerializer.new(company)
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end
end
