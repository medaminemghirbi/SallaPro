class ClientSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :birthday, :address, :phone_number, :country,
             :email, :full_name, :unique_code, :status, :initials, :age, :member_since,
             :latitude, :longitude, :user_image_url, :created_at, :updated_at

  def full_name
    "#{object.firstname} #{object.lastname}"
  end

  def unique_code
    "CLT#{object.id.to_s[0..7].upcase}"
  end

  def initials
    "#{object.firstname&.first&.upcase}#{object.lastname&.first&.upcase}"
  end

  def age
    return nil unless object.birthday.present?
    
    now = Time.current.to_date
    age = now.year - object.birthday.year
    age -= 1 if now < object.birthday + age.years
    age
  end

  def member_since
    object.created_at&.strftime('%B %Y')
  end

  def status
    object.status || 'active'
  end
end
