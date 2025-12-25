class Admin < User
  ##scopes
  scope :current, -> { where(is_archived: false) }
  has_one :company, foreign_key: 'user_id', dependent: :destroy
  ##Includes

  ## Callbacks

  ## Validations

  ## Associations

  private
end
