class Api::V1::CategoriesController < ApplicationController
  before_action :authorize_request
  def index
    render json: Categorie.all
  end
end
