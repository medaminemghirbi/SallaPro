class Api::V1::UsersController < ApplicationController
  before_action :authorize_request, except: %i[plateform_stats gender_stats count_all_for_admin update_image_user update_location top_consultation_gouvernement]
  # ************************* custom functionlity ***************************#

  def count_all_for_admin
    @apointements = Consultation.current.all.count
    @patients = Patient.current.all.count
    @blogs = Blog.current.all.count
    @doctors = Doctor.current.all.count
    @maladies = Maladie.current.all.count

    render json: {
      apointements: @apointements,
      patients: @patients,
      blogs: @blogs,
      doctors: @doctors,
      maladies: @maladies
    }
  end

  def top_consultation_gouvernement
    top_consultations = Consultation.joins(:patient)
                                     .group('users.location')
                                     .order('COUNT(users.location) DESC')
                                     .limit(24)
                                     .count
  
    render json: top_consultations
  end
  
  
  def gender_stats
    gender_counts = User
      .group(:gender)
      .order(Arel.sql('COUNT(*) DESC'))
      .count
  
    # Transform to array of hashes
    result = gender_counts.map { |gender, total| { gender: gender, total: total } }
  
    render json: result

    
  end
  
  
  def plateform_stats
    plateform_counts = User
      .where.not(plateform: nil)  # Reject NULL values
      .group(:plateform)
      .order(Arel.sql('COUNT(*) DESC'))
      .count
  
    result = plateform_counts.map { |platform, total| { plateform: platform, total: total } }
  
    render json: result
  end
  

  def update_location
    @user = User.find(params[:id])
    if @user.update(params_location_doctor)
      render json: @user, methods: [:user_image_url]
    else
      render json: @user.errors, statut: :unprocessable_entity
    end
  end

  def update_image_user
    @user = User.find(params[:id])
    if @user.update(params_image_user)
      render json: @user, methods: [:user_image_url]
    else
      render json: @user.errors, statut: :unprocessable_entity
    end
  end

  def update_email_notifications
    @user = User.find(params[:id])

    if @user.update(is_emailable: params[:is_emailable])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  # Update system notification preference
  def update_system_notifications
    @user = User.find(params[:id])

    if @user.update(is_notifiable: params[:is_notifiable])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  # Update SMS notification preference
  def update_sms_notifications
    @user = User.find(params[:id])

    if @user.update(is_smsable: params[:is_smsable])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  def working_saturday
    @user = User.find(params[:id])

    if @user.update(working_saturday: params[:working_saturday])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  def sms_notifications
    @user = User.find(params[:id])

    if @user.update(is_smsable: params[:is_smsable])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  def working_online
    @user = User.find(params[:id])

    if @user.update(working_on_line: params[:working_on_line])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  def changeLanguage
    @user = User.find(params[:id])

    if @user.update(language: params[:language])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages  # Use @user.errors directly instead of @user.user_setting.errors
      }, status: :unprocessable_entity
    end
  end

  def get_defaut_language
    @user = User.current.find_by(id: params[:user_id]) # Use `find_by` to fetch a single user
    if @user
      render json: {language: @user.language}
    else
      render json: {error: "User not found"}, status: :not_found
    end
  end

  def update_wallet_amount
    @user = User.find(params[:id])
    if @user.update(amount: params[:amount])
      render json: @user, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  def update_phone_number
    @user = User.find(params[:id])
    if @user.update(phone_number: params[:phone_number])
      render json: @user, status: :ok, methods: [:user_image_url]
    else
      render json: {
        status: 422,
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  def update_user_informations
    @user = User.find(params[:id])
    if @user.update(params_informations_user)
      render json: @user, methods: [:user_image_url]
    else
      render json: @user.errors, statut: :unprocessable_entity
    end
  end

  def update_password_user
    @user = User.find(params[:id])
    # Check if the old password is correct
    unless @user.authenticate(params[:oldPassword])
      return render json: {error: "Old password is incorrect"}, status: :unauthorized
    end

    # Ensure the new password meets the required strength criteria
    if !password_strength_valid?(params[:newPassword])
      return render json: {error: "Password does not meet strength requirements"}, status: :unprocessable_entity
    end

    # Update the user's password
    if @user.update(password: params[:newPassword])
      render json: @user, methods: [:user_image_url], status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end


    def upload_verification_pdf
      current_doctor = User.find(params[:id])
      current_doctor.verification_pdf.attach(params[:verification_pdf])
      render json: { message: 'Verification PDF uploaded' }, status: :ok
    end
  # ************************* les fonctions private de classe ***********************#
  private

  def password_strength_valid?(password)
    return false unless password.length >= 8
    return false unless /[A-Z]/.match?(password) # At least one uppercase letter
    return false unless /\d/.match?(password)    # At least one number
    return false unless /[\W_]/.match?(password)  # At least one special character

    true
  end

  def params_password_user
    params.permit(:id, :oldPassword, :newPassword)
  end

  def params_image_user
    params.permit(:id, :avatar)
  end

  def params_informations_user
    permitted_params = params.permit(:id, :civil_status, :gender, :birthday, :lastname, :firstname, :location, :radius, :phone_number, :about_me)
    permitted_params[:radius] = permitted_params[:radius].to_i if permitted_params[:radius].present?
    permitted_params
  end

  def params_location_doctor
    params.permit(:id, :latitude, :longitude)
  end
end
