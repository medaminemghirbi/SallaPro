class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :firstname, :lastname, :address, :birthday, 
             :gender, :civil_status, :is_archived, :order, 
             :plan, :language, :confirmed_at, :type, :jti, 
             :created_at, :updated_at
             
  def type
    object.type # returns "Patient", "Doctor", etc.
  end
end
