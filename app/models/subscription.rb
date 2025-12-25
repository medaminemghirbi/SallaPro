class Subscription < ApplicationRecord
  belongs_to :company

  enum plan: { trial: 0, monthly: 1 }
  enum status: { active: 0, expired: 1, cancelled: 2 }

  def active_subscription?
    active? && end_date >= Date.today
  end
end
