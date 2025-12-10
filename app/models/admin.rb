class Admin < User
  ##scopes
  scope :current, -> { where(is_archived: false) }
  ##Includes

  ## Callbacks

  ## Validations

  ## Associations

  private
end
