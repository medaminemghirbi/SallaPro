class ClientSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :birthday, :address, :phone_number, :country, :email, :full_name, :unique_code, :created_at, :updated_at, :user_image_url

  def full_name
    "#{object.firstname} #{object.lastname}"
  end

    def unique_code
    # prends les 8 premiers caractères de l'UUID et mets un préfixe
    "CLT#{object.id.to_s[0..7].upcase}"
  end
end
