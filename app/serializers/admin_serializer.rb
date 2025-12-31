class AdminSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :email, :confirmed_at, :created_at, :updated_at
end
