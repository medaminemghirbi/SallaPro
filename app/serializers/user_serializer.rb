class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers 
  attributes :id, :email, :firstname, :lastname, :address, :birthday, 
             :gender, :civil_status, :is_archived, :order, 
             :plan, :language, :confirmed_at, :type, :jti, 
             :created_at, :updated_at, :user_image_url
             
  def type
    object.type # returns "Patient", "Doctor", etc.
  end

    def user_image_url
    # Get the URL of the associated image
    object.avatar.attached? ? url_for(object.avatar) : nil
  end
end
  