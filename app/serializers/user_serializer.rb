class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :firstname, :lastname, :address, :birthday, :gender, 
             :civil_status, :is_archived, :order, :location, :specialization, 
             :latitude, :longitude, :description, :code_doc, :website, :twitter, 
             :youtube, :facebook, :linkedin, :phone_number, :medical_history, 
             :plan, :custom_limit, :radius, :is_emailable, :is_notifiable, 
             :is_smsable, :working_saturday, :working_on_line, :amount, 
             :created_at, :updated_at, :language, :confirmation_code, 
             :confirmed_at,  :type, :is_verified,
             :confirmation_code_generated_at, :about_me, :jti, :user_image_url, :user_image_url_mobile, :verification_pdf_url

  def user_image_url
    object.user_image_url
  end

  def user_image_url_mobile
    object.user_image_url_mobile
  end
  def type
    object.type # This ensures "Patient", "Doctor", etc.
  end
end
