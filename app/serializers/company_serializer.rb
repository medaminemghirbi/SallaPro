class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name,  :billing_address, :phone_number, :description, :created_at, :updated_at, :company_image_url
  attributes :subscription_active, :subscription_plan, :subscription_status, :subscription_end_date
  # Include related admin and company type
  belongs_to :admin, serializer: AdminSerializer
  has_one :subscription, serializer: SubscriptionSerializer

  
  def company_image_url
    # Get the URL of the associated image
    object.company_image_url
  end

  def subscription_active
    object.subscription&.active_subscription? || false
  end

  def subscription_plan
    object.subscription&.plan
  end

  def subscription_status
    object.subscription&.status
  end

  def subscription_end_date
    object.subscription&.end_date
  end
end
