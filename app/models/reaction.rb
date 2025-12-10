class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :blog
  enum reaction_type: { like: 0, dislike: 1 }

  validates :reaction_type, presence: true

end
