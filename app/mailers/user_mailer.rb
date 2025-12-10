class UserMailer < ApplicationMailer
  default from: "DermaPro@System.com"
  def registration_confirmation(user)
    @user = user
    mail(to: " <#{user.email}>", subject: "Registration Confirmation")
  end

  def confirmation_instructions(record, token, opts = {})
    @user = record
    @token = token
    opts[:subject] ||= "Confirm Your Account"
    mail(to: @user.email, subject: opts[:subject])
  end

  def forgot_password(user)
    @user = user
    @greeting = "Hi"
    mail to: user.email, subject: "Reset password instructions"
  end

  def confirmation_email(user)
    @user = user
    @confirmation_code = user.confirmation_code
    mail(to: @user.email, subject: "Email Confirmation Code")
  end
end
