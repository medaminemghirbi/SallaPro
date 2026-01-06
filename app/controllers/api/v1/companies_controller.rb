class Api::V1::CompaniesController < ApplicationController
  before_action :authorize_request
  before_action :set_company, only: [:show, :update, :destroy]
  def index
    # Eager load admin to avoid N+1 queries
    companies = Company.includes(:admin).all

    # Render JSON using ActiveModel::Serializer
    render json: companies, each_serializer: CompanySerializer
  end

  def create
    ActiveRecord::Base.transaction do
      # 1️⃣ Create the admin user
      admin_params = params.permit(:firstname, :lastname, :email, :password, :password_confirmation)
      admin = User.create!(admin_params.merge(type: "Admin"))

      # 2️⃣ Create the company linked to this admin
      company_params = params.permit(:company_name, :billing_address, :description, :categorie_id)
      company = Company.create!(
        name: company_params[:company_name],
        billing_address: company_params[:billing_address] || admin.email,
        description: company_params[:description],
        categorie_id: company_params[:categorie_id],
        user_id: admin.id
      )

      # 4️⃣ Return JSON of both
      render json: {
        admin: AdminSerializer.new(admin),
        company: CompanySerializer.new(company)
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages[0] }, status: :unprocessable_entity
  end



  def show
    company = Company
                .includes(:admin)
                .find(params[:id])

    render json: company,
          serializer: CompanySerializer,
          status: :ok

  rescue ActiveRecord::RecordNotFound
    render json: { errors: "Company not found" }, status: :not_found
  end

    def update
    ActiveRecord::Base.transaction do
      # Update company attributes
      company_params_filtered = company_params
      @company.update!(company_params_filtered)
      render json: @company, status: :ok
    end
    rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /companies/:id
  def destroy
    @company.update!(active: false) # soft delete
    render json: { message: "Company archived successfully" }, status: :ok
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_company
    @company = Company.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: "Company not found" }, status: :not_found
  end

def company_params
  params.require(:company).permit(:name, :billing_address, :description, :active, :avatar, :phone_number, :categorie_id)
end


end
