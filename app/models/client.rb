class Client < User
  ##scopes
  ##Includes

  ## Callbacks

  ## Validations

  ## Associations
  has_one :company, foreign_key: 'user_id', dependent: :destroy

  private
end
