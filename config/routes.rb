require "sidekiq/web"
# require 'sidekiq-scheduler/web'
Rails.application.routes.draw do
  devise_for :users, path: "api", path_names: {registration: "sign_up", sessions: "sign_in", sign_out: "sign_out"}, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations"
  }

  # add root par defaut for api
  root to: "static#home"

  # Mount action cable for real time (chat Or Notification)
  mount ActionCable.server => "/cable"
  mount Sidekiq::Web => "/sidekiq"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == "admin" && password == "password123"
  end
  # EndPoints
  # Authentification System End Points
  resources :sessions, only: [:create]
  delete :logout, to: "sessions#logout"
  get :logged_in, to: "sessions#logged_in"
  # add registration (register page ) + confirmation de l'email
  resources :registrations, only: [:create] do
    member do
      get :confirm_email
    end
  end

  namespace :api do
    namespace :v1 do
      resources :password_resets
      resources :patients

      resources :users do
        member do
          put "email_notifications", to: "users#update_email_notifications"
          put "system_notifications", to: "users#update_system_notifications"
          put "working_saturday", to: "users#working_saturday"
          put "sms_notifications", to: "users#sms_notifications"
          put "working_online", to: "users#working_online"
          put "update_wallet_amount", to: "users#update_wallet_amount"
          put "update_phone_number", to: "users#update_phone_number"
          put "changeLanguage", to: "users#changeLanguage"
        end
      end
      get "messages/:message_id/images/:image_id", to: "messages#download_image"
      delete "destroy_all", to: "messages#destroy_all"

      get "reload_data", to: "scrapers#run"
      get "last_run", to: "scrapers#last_run"
      get "code_room_exist", to: "consultations#code_room_exist"
      get "getAllEmails/:type/:id", to: "custom_mails#get_all_emails_doctor"
      get "deleteAllEmail/:type/:id", to: "custom_mails#delete_all_email"

      get "doctor_consultations_today/:doctor_id", to: "consultations#doctor_consultations_today"

      get "doctor_appointments/:doctor_id", to: "consultations#doctor_appointments"
      get "consultations/available_seances/:doctor_id", to: "consultations#available_seances_for_year"
      get "doctor_consultations/:doctor_id", to: "consultations#doctor_consultations"
      get "available_time_slots/:date/:doctor_id", to: "consultations#available_time_slots"
      get "verified_blogs", to: "blogs#verified_blogs"
      get "my_blogs/:doctor_id", to: "blogs#my_blogs"
      patch "all_all_verification", to: "blogs#all_all_verification"
      get "statistique", to: "users#count_all_for_admin"
      get "top_consultation_gouvernement", to: "users#top_consultation_gouvernement"
      get "gender_stats", to: "users#gender_stats"
      get "plateform_stats", to: "users#plateform_stats"
      get "doctor_stats/:doctor_id", to: "doctors#getDoctorStatistique"
      get "patient_stats/:patient_id", to: "patients#getPatientStatistique"

      patch "updatedoctorimage/:id", to: "doctors#updatedoctorimage"
      patch "updatedoctor/:id", to: "doctors#updatedoctor"
      patch "updatepassword/:id", to: "doctors#updatepassword"
      patch "update_password_user/:id", to: "users#update_password_user"
      patch "update_user_informations/:id", to: "users#update_user_informations"

      get "download_file/:id", to: "documents#download"
      delete "delete_all_documents/:id", to: "documents#delete_all_documents"
      get "nearest_doctors", to: "doctors#nearest"

      get "patient_appointments/:patient_id", to: "consultations#patient_appointments"
      get "doctors/:id/patients", to: "doctors#show_patients"
      post "rate_doctor", to: "doctors#rate_doctor"
      get "check_rating", to: "doctors#check_rating"

      post "payments/generate", to: "payments#create_payment"
      get "payments/verify", to: "payments#verify_payment"
      get "payments/:id/generate_facture", to: "payments#generate_facture"

      get "get_defaut_language/:user_id", to: "users#get_defaut_language"
      get "search_doctors", to: "doctors#search_doctors"
      get "index_home", to: "doctors#index_home"

      get "doctor_services/:id", to: "services#doctor_services"
      post "doctor_add_services/:id/add_services", to: "services#doctor_add_services"
      put "update_mobile_display", to: "services#update_mobile_display"
      get "get_doctor_details/:id", to: "doctors#fetch_doctor_data"
      resources :certificates, only: [:show] do
        get :download, on: :member
      end

      patch 'upload_verification_pdf', to: 'users#upload_verification_pdf'

    end
  end
end
