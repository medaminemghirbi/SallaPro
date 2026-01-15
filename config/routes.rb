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
      resources :categories, only: [:index]
      resources :clients, only: [:create, :index, :show, :update, :destroy] do
        collection do
          post :export
          get :stats
          get :countries
        end
      end

      resources :employees, only: [:index, :show, :create, :update, :destroy] do
        collection do
          post :export
        end
      end

      resources :companies, only: [:index, :create, :show, :update, :destroy] do
        # Employee routes under company
        resources :employees, only: [:index, :show, :update] do
          collection do
            get :stats
            get :departments_list
            get :positions
          end
        end

        # Department routes
        resources :departments, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :stats
            get :list
            post :export
          end
          member do
            get :employees
          end
        end

        resources :documents, controller: 'company_documents', only: [:index, :show, :create, :update, :destroy] do
          member do
            get :download
          end
          collection do
            delete :bulk_delete
            get :categories
            get :document_types
            get :stats
          end
        end
        resources :materials, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :categories
            get :stats
            get :alerts
          end
          resources :maintenance_records, only: [:index, :show, :create, :update, :destroy] do
            member do
              post :complete
              post :cancel
            end
          end
        end
        resources :suppliers, only: [:index, :show, :create, :update, :destroy] do
          collection do
            post :export
            get :categories
            get :stats
          end
        end

        resources :venues, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :types
            get :stats
            get :available
            post :export
          end
          member do
            delete 'images/:image_id', to: 'venues#destroy_image', as: :destroy_image
          end
        end

        # Venue Contracts
        resources :venue_contracts, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :stats
            get :status_options
            get :event_types
          end
          member do
            post :convert_to_devis
            post :convert_to_contract
            post :sign
            get :generate_pdf
          end
        end

        # Venue Reservations
        resources :venue_reservations, only: [:index, :show, :update, :destroy] do
          collection do
            get :stats
            get :calendar
            get :check_availability
          end
          member do
            post :cancel
            post :complete
          end
        end
      end

      # Notifications
      resources :notifications, only: [:index, :show, :destroy] do
        member do
          post :mark_as_read
          post :mark_as_unread
          post :archive
        end
        collection do
          get :unread_count
          post :mark_all_as_read
          delete :clear_all
        end
      end

      resources :calendars, only: [:index]  
      resources :users do
        member do
          post :resend_confirmation
        end
      end
      get 'current_user_info', to: 'users#current_user_info'
      get 'current_user_role', to: 'users#current_user_role'
      get 'current_company_info', to: 'users#current_company_info'
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
      get "statistique", to: "users#count_all_for_admin"
      get "gender_stats", to: "users#gender_stats"
      get "plateform_stats", to: "users#plateform_stats"
      get "patient_stats/:patient_id", to: "patients#getPatientStatistique"

      patch "update_password_user/:id", to: "users#update_password_user"
      patch "update_user_informations/:id", to: "users#update_user_informations"

      get "download_file/:id", to: "documents#download"
      delete "delete_all_documents/:id", to: "documents#delete_all_documents"

      post "payments/generate", to: "payments#create_payment"
      get "payments/verify", to: "payments#verify_payment"
      get "payments/:id/generate_facture", to: "payments#generate_facture"

      get "get_defaut_language/:user_id", to: "users#get_defaut_language"

      resources :certificates, only: [:show] do
        get :download, on: :member
      end

      patch 'upload_verification_pdf', to: 'users#upload_verification_pdf'

    end
  end
end
