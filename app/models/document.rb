class Document < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_one_attached :file

  scope :current, -> { where(is_archived: false) }

  belongs_to :doctor

  validates :title, presence: true


  def document_url
    # Get the URL of the associated image
    file.attached? ? url_for(file) : nil
  end
end
