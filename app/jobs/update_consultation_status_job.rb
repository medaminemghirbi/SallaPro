class UpdateConsultationStatusJob < ApplicationJob
  queue_as :default

  def perform
    Consultation.approved.where("appointment < ?", 2.hours.ago).find_each do |consultation|
      consultation.update!(status: :finished)
    end
  end
end
