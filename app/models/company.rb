class Company < ApplicationRecord
  belongs_to :admin, class_name: 'User', foreign_key: 'user_id'
  belongs_to :categorie, optional: true
  has_many :company_documents, dependent: :destroy
  has_many :materials, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :venue_contracts, dependent: :destroy
  has_many :venue_reservations, dependent: :destroy
  
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

  def employees_count
    employees.count
  end

  def departments_count
    departments.count
  end
end
