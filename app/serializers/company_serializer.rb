class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :created_at, :updated_at

  # Include related admin and company type
  belongs_to :admin, serializer: AdminSerializer
  belongs_to :company_type, serializer: CompanyTypeSerializer
end
