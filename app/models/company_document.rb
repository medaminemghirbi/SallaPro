# frozen_string_literal: true

class CompanyDocument < ApplicationRecord
  belongs_to :company
  belongs_to :uploaded_by, class_name: 'User'

  has_one_attached :file

  # Validations
  validates :name, presence: true
  validates :file, presence: true, on: :create

  # Document types
  DOCUMENT_TYPES = %w[contract invoice report policy manual certificate other].freeze
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }, allow_nil: true

  # Scopes
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_type, ->(type) { where(document_type: type) if type.present? }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :public_documents, -> { where(is_public: true) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_name, ->(query) { where('name ILIKE ?', "%#{query}%") if query.present? }

  # Callbacks
  before_save :set_file_metadata, if: -> { file.attached? && file.blob.changed? }

  include Rails.application.routes.url_helpers

  def file_url
    file.attached? ? url_for(file) : nil
  end

  def file_name
    file.attached? ? file.filename.to_s : nil
  end

  def uploader_name
    uploaded_by ? "#{uploaded_by.firstname} #{uploaded_by.lastname}" : 'Unknown'
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def human_file_size
    return nil unless file_size

    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(2)} KB"
    else
      "#{(file_size / (1024.0 * 1024.0)).round(2)} MB"
    end
  end

  private

  def set_file_metadata
    if file.attached?
      self.file_size = file.blob.byte_size
      self.file_type = file.blob.content_type
    end
  end
end
