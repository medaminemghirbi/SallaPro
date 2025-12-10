class Consultation < ApplicationRecord
  ## Scopes
  enum status: {pending: 0, approved: 1, rejected: 2, finished: 4}
  enum appointment_type: {onsite: 0, online: 1}

  scope :current, -> { where(is_archived: false) }
  scope :payed, -> { where(is_payed: true) }

  # after_create_commit { broadcast_notification }

  ## Includes

  ## Callbacks

  ## Validations
  validates :appointment, presence: true
  validate :verified_consultation_booked, on: :create

  ## Associations
  belongs_to :doctor, class_name: "User", foreign_key: "doctor_id"
  belongs_to :patient, class_name: "User", foreign_key: "patient_id"
  has_one :payment, dependent: :destroy
  has_one :rating, dependent: :destroy # if consultation is deleted, the rating is too
  has_one :consultation_report, dependent: :destroy
  has_many :prediction


  TIME_SLOTS = [
    {time: "09:00"},
    {time: "09:30"},
    {time: "10:00"},
    {time: "10:30"},
    {time: "11:00"},
    {time: "11:30"},
    {time: "12:00"},
    {time: "13:30"},
    {time: "14:00"},
    {time: "14:30"},
    {time: "15:00"},
    {time: "15:30"},
    {time: "16:00"}
  ]
  def generate_room_code
    self.room_code = loop do
      random_code = SecureRandom.alphanumeric(8).upcase
      break random_code unless Consultation.exists?(room_code: random_code)
    end
  end

  def within_120_minutes_before_appointment?
    Time.current >= (appointment - 120.minutes) && Time.current < appointment
  end
    # Ensure that you can access a report easily
    def has_report?
      consultation_report.present?
    end
  private

  def verified_consultation_booked
    if Consultation.where(appointment: appointment, status: :approved, doctor_id: doctor_id).exists?
      errors.add(:appointment, "is already booked for an approved consultation at this time.")
    end
  end

  # def broadcast_notification
  #   ActionCable.server.broadcast("ConsultationChannel", {
  #     id: id,
  #     appointment: appointment,
  #     status: status,
  #     doctor_id: doctor_id,
  #     patient_id: patient_id,
  #     refus_reason: refus_reason
  #   })
  # end


end
