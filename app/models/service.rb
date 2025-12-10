class Service < ApplicationRecord
  has_many :doctor_services, dependent: :destroy
  has_many :doctors, through: :doctor_services
end
