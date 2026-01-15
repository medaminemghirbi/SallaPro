class EmployeeMinimalSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :full_name, :email, :position, :avatar_url

  def full_name
    object.full_name
  end

  def avatar_url
    object.user_image_url
  end
end
