class Company < ApplicationRecord
  belongs_to :admin, class_name: 'User', foreign_key: 'user_id'
  belongs_to :categorie, optional: true
  validates :name, presence: true
  has_one_attached :avatar, dependent: :destroy

  include Rails.application.routes.url_helpers
  def active?
    self.active
  end
  def admin_name
    admin ? "#{admin.firstname} #{admin.lastname}" : "N/A"
  end
  
    def company_image_url
    # Get the URL of the associated image
    avatar.attached? ? url_for(avatar) : nil
  end

end
