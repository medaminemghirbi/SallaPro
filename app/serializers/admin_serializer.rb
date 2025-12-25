class AdminSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :email, :created_at, :updated_at
end
