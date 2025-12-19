class Api::V1::CompanyTypesController < ApplicationController
  before_action :authorize_request
  def index
    render json: CompanyType.all
  end
end
