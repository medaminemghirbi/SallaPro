class Api::Mobile::MaladiesController < ApplicationController
    before_action :set_maladie, only: [:show, :update, :destroy]
    def index
        @maladies = Maladie.all.order(:order)
        render json: @maladies, methods: [:diseas_image_url_mobile]
    end
    def show
        render json: @maladie
    end
  
    private
      def set_maladie
        @maladie = Maladie.find(params[:id])
      end
  end