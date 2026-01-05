class Client < User
  ##scopes
  ##Includes

  ## Callbacks

  ## Validations

  ## Associations
  has_one :company, foreign_key: 'user_id', dependent: :destroy
  # Validations
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  
  # Virtual attribute for full name
  def full_name
    "#{firstname} #{lastname}"
  end
  
  # Scopes for filtering
  scope :search_by_term, ->(term) {
    where("LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(email) LIKE ?",
          "%#{term.downcase}%", "%#{term.downcase}%", "%#{term.downcase}%")
  }
  
  scope :by_resource_type, ->(type) { where(resource_type: type) }

  private
end
