class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name,  :billing_address, :active, :phone_number, :description, :created_at, :updated_at, :company_image_url, :categorie
  # Include related admin and company type
  belongs_to :admin, serializer: AdminSerializer

  
  def company_image_url
    # Get the URL of the associated image
    object.company_image_url
  end

  def categorie
    object.categorie if object.categorie.present?
  end

end
