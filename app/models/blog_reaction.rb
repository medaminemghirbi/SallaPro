class BlogReaction < ApplicationRecord
    belongs_to :user
    belongs_to :blog
    validates :reaction, inclusion: { in: %w[like dislike] }
  end