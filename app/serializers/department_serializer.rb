class DepartmentSerializer < ActiveModel::Serializer
  attributes :id, :name, :code, :description, :color, :active,
             :employees_count, :manager_id, :manager_name,
             :created_at, :updated_at

  def manager_name
    object.manager_name
  end
end
