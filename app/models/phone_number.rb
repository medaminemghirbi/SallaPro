class PhoneNumber < ApplicationRecord

  scope :current, -> { where(is_archived: false) }

  belongs_to :doctor

  validates :number, presence: true, uniqueness: true
  validates :phone_type, presence: true
end
