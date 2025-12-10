class Api::V1::MaladiesController < ApplicationController
  before_action :set_maladie, only: [:show, :update, :destroy]
  def index
      @maladies = Maladie.all.order(:order)
      render json: @maladies, methods: [:diseas_image_url]
  end
  def show
      render json: @maladie
  end
  def create
      @maladie = Maladie.new(maladie_params)
      if @maladie.save
      render json: @maladie, status: :created
      else
      render json: @maladie.errors, status: :unprocessable_entity
      end
  end
  def update
    if @maladie.update(maladie_params)
      render json: @maladie
    else
      render json: @maladie.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @maladie.update(is_archived: true)
  end

  private
    def set_maladie
      @maladie = Maladie.find(params[:id])
    end
    def maladie_params
      params.permit(:maladie_name, :maladie_description, :synonyms, :symptoms, :causes, :treatments, :prevention, :diagnosis, :references  )
    end
end