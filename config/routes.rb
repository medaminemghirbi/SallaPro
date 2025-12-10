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
  get "appointment_by_location/:location", to: "static#appointment_by_location"

  # Mount action cable for real time (chat Or Notification)
  mount ActionCable.server => "/cable"
  mount Sidekiq::Web => "/sidekiq"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == "admin" && password == "password123" # Change to your credentials
  end
  # EndPoints
  # Authentification System End Points
  resources :sessions, only: [:create]
  delete :logout, to: "sessions#logout"
  get :logged_in, to: "sessions#logged_in"
  get "weeks/:doctor_id(/:year)", to: "weeks#index"
  # add registration (register page ) + confirmation de l'email
  resources :registrations, only: [:create] do
    member do
      get :confirm_email
    end
  end
  post "predict/:doctor_id/", to: "predictions#predict"
  post "predict/:consultation_id", to: "predictions#predict"

  post "sent_report/:patient_id/:prediction_id", to: "predictions#sent_report"
  get "predictions_by_consultations/:consultation_id", to: "predictions#predictions_by_consultations"

  
  resources :predictions
  get "download_file/:id", to: "predictions#download"

  namespace :api do
    namespace :v1 do
      resources :password_resets

      resources :doctors do
        post "activate_compte", on: :member
        patch :verify, on: :member
      end
      resources :patients
      resources :consultations, only: [:show, :create, :destroy, :update] do
        resource :consultation_report, only: [:create, :show] # To create and view the report
        get 'report/download', to: 'consultation_reports#download', as: 'download_report'
      end
      resources :blogs
      resources :maladies
      resources :holidays
      resources :messages
      resources :services, only: [:index, :destroy]
      resources :doctor_services, only: [:destroy]

      resources :notifications, only: [:create, :index]
      resources :phone_numbers
      resources :custom_mails

      resources :documents

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
      patch "update_location/:id", to: "users#update_location"
      get "all_locations", to: "doctors#unique_locations"
      get "doctor_stats/:doctor_id", to: "doctors#getDoctorStatistique"
      get "patient_stats/:patient_id", to: "patients#getPatientStatistique"

      get "get_doctors_by_locations/:location", to: "doctors#get_doctors_by_locations"
      get "location_details", to: "locations#details"
      patch "updatedoctorimage/:id", to: "doctors#updatedoctorimage"
      patch "updatedoctor/:id", to: "doctors#updatedoctor"
      patch "updatepassword/:id", to: "doctors#updatepassword"
      patch "update_password_user/:id", to: "users#update_password_user"
      patch "update_user_informations/:id", to: "users#update_user_informations"

      get "download_file/:id", to: "documents#download"
      delete "delete_all_documents/:id", to: "documents#delete_all_documents"
      post "update_address", to: "locations#update_address"
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

  namespace :api do
    namespace :mobile do
      resources :registrations, only: [:create] do
        collection do
          post :confirm_email
        end
      end
      get "patient_consultations_today/:patient_id", to: "consultations#patient_consultations_today"
      get "doctor_list/:location", to: "doctors#nearest"
      get "patient_appointments/:patient_id", to: "consultations#patient_appointments"
      delete "archive_consultation/:id", to: "consultations#destroy"
      get "get_selected_doctor/:id", to: "doctors#get_selected_doctor"
      put "set_app_config", to: "app_configs#set_app_config"
      post "sessions", to: "sessions#sign_in_mobile"
      get "sessions_qr", to: "sessions#login_qr"
      post "create_demande", to: "consultations#add_new_demande"
      resources :messages
      resources :users
      patch "update_settings", to: "users#update_settings"
      resources :maladies
      post "predict/patient/:patient_id", to: "predictions#predict"
      post "predict/doctor/:doctor_id", to: "predictions#predict"
      

      get 'verify', to: 'auth#verify'
      put "changeLanguage", to: "users#changeLanguage"
      get "doctor_consultations_today/:doctor_id", to: "consultations#doctor_consultations_today"
      get "doctor_appointments/:doctor_id", to: "consultations#doctor_appointments"
      post 'save_expo_token', to: 'users#save_token'
      get 'doctor_details/:id', to: 'doctors#doctor_details'
      resources :consultations, only: [:update]
    end
  end
  # resources :users
end
