class Api::V1::CustomMailsController < ApplicationController
  def get_all_emails_doctor
    if params[:type] == "Doctor"
      emails = CustomMail.where(doctor_id: params[:id]).order(sent_at: :desc)
    elsif params[:type] == "Patient"
      emails = CustomMail.where(patient_id: params[:id]).order(sent_at: :desc)
    else
      render json: {error: 'Invalid type parameter. Must be "doctor" or "patient".'}, status: :unprocessable_entity
      return
    end

    render json: emails
  end

  def destroy
    @message = CustomMail.find(params[:id])
    @message.destroy
  end

  def delete_all_email
    if params[:type] == "Doctor"
      emails_deleted_count = CustomMail.where(doctor_id: params[:id]).delete_all
    elsif params[:type] == "Patient"
      emails_deleted_count = CustomMail.where(patient_id: params[:id]).delete_all
    else
      render json: {error: 'Invalid type parameter. Must be "Doctor" or "Patient".'}, status: :unprocessable_entity
      return
    end

    render json: {message: "#{emails_deleted_count} emails successfully deleted.", count: emails_deleted_count}
  end
end
