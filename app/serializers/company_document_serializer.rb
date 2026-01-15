# frozen_string_literal: true

class CompanyDocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :document_type, :category,
             :file_size, :file_type, :is_public, :expires_at,
             :metadata, :created_at, :updated_at,
             :file_url, :file_name, :uploader_name, :human_file_size,
             :expired

  def file_url
    object.file_url
  end

  def file_name
    object.file_name
  end

  def uploader_name
    object.uploader_name
  end

  def human_file_size
    object.human_file_size
  end

  def expired
    object.expired?
  end
end
