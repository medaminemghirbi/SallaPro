class Company < ApplicationRecord
  belongs_to :admin, class_name: "User", foreign_key: "user_id"
  validates :name, presence: true
  belongs_to :company_type

  def active?
    self.active
  end
  def admin_name
    admin ? "#{admin.firstname} #{admin.lastname}" : "N/A"
  end
  
end
