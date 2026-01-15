class DepartmentMinimalSerializer < ActiveModel::Serializer
  attributes :id, :name, :code, :color, :employees_count
end
