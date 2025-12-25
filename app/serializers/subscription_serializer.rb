class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :plan, :status, :start_date, :end_date, :active

  belongs_to :company

  def active
    object.active_subscription?
  end
end
