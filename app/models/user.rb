class User < ApplicationRecord
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  self.table_name = "users"
  ## STI Type Checks
  def admin?; type == "Admin"; end
  def superadmin?; type == "Superadmin"; end
  def employee?; type == "Employee"; end
  def client?; type == "Client"; end
  enum gender: [:male, :female]
  enum plateform: [:web, :mobile]

  enum civil_status: [:Mr, :Mrs, :Mme, :other]
  # encrypts :email, deterministic: true
  # #scopes
  scope :current, -> { where(is_archived: false) }

  # #Includes
  include Rails.application.routes.url_helpers
  ## Callbacks
  before_create :attach_avatar_based_on_gender
  ## Validations
  validates :email, uniqueness: true

  ## Associations
  has_one_attached :avatar, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :assigned_materials, class_name: 'Material', foreign_key: 'assigned_to_id', dependent: :nullify

  def verification_pdf_url
    # Get the URL of the associated image
    verification_pdf.attached? ? url_for(verification_pdf) : nil
  end

  def user_image_url
    # Get the URL of the associated image
    avatar.attached? ? url_for(avatar) : nil
  end

  def confirmation_code_expired?
    confirmation_code_generated_at.nil? || (Time.current > (confirmation_code_generated_at + 5.minute))
  end

  def send_password_reset
    generate_token(:reset_password_token)
    self.reset_password_sent_at = Time.zone.now
    save!
    UserMailer.forgot_password(self).deliver # This sends an e-mail with a link for the user to reset the password
  end

  private

  def attach_avatar_based_on_gender
    if male?
      avatar.attach(io: File.open(Rails.root.join("app", "assets", "images", "default_avatar.png")), filename: "default_avatar.png", content_type: "image/png")
    else
      avatar.attach(io: File.open(Rails.root.join("app", "assets", "images", "default_female_avatar.png")), filename: "default_female_avatar.png", content_type: "image/png")
    end
  end



  # This generates a random password reset token for the user
  def generate_token(column)
    loop do
      self[column] = SecureRandom.urlsafe_base64
      break unless User.exists?(column => self[column])
    end
  end

end
