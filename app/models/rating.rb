class Rating < ApplicationRecord
  belongs_to :consultation

  validates :consultation_id, uniqueness: true # Enforces the 0..1 relationship
  validates :rating_value, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5}, allow_nil: true # Optional validation
end
