class EmployeeSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :full_name, :initials, :email,
             :phone_number, :address, :country,
             :latitude, :longitude, :coordinates,
             :position, :status, :employee_id, :hire_date, :tenure,
             :department_id, :department_name,
             :contract_type, :work_schedule, :salary,
             :skills, :emergency_contact_name, :emergency_contact_phone,
             :is_archived, :avatar_url, :created_at, :updated_at

  def full_name
    object.full_name
  end

  def initials
    object.initials
  end

  def tenure
    object.tenure
  end

  def department_name
    object.department_name
  end

  def avatar_url
    object.user_image_url
  end

  def coordinates
    return nil unless object.latitude && object.longitude
    { lat: object.latitude, lng: object.longitude }
  end
end
