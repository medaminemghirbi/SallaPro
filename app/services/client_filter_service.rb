# frozen_string_literal: true

class ClientFilterService
  attr_reader :scope, :params

  def initialize(scope = Client.all, params = {})
    @scope = scope
    @params = params
  end

  def self.call(scope = Client.all, params = {})
    new(scope, params).filter
  end

  def filter
    filtered_scope = scope

    filtered_scope = filter_by_ids(filtered_scope)
    filtered_scope = filter_by_search(filtered_scope)
    filtered_scope = filter_by_resource_type(filtered_scope)

    filtered_scope
  end

  private

  def filter_by_ids(filtered_scope)
    client_ids = params[:clientIds] || params[:client_ids]
    return filtered_scope unless client_ids.present? && client_ids.any?

    filtered_scope.where(id: client_ids)
  end

  def filter_by_search(filtered_scope)
    search_term = params[:search] || params[:filters]&.dig(:search)
    return filtered_scope if search_term.blank?

    search_pattern = "%#{search_term.downcase}%"
    filtered_scope.where(
      'LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone_number) LIKE ?',
      search_pattern, search_pattern, search_pattern, search_pattern
    )
  end

  def filter_by_resource_type(filtered_scope)
    resource_type = params[:resourceType] || params[:resource_type] || params[:filters]&.dig(:resourceType)
    return filtered_scope if resource_type.blank?

    filtered_scope.where(resource_type: resource_type)
  end
end
