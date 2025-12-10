class Api::V1::AdminsController < ApplicationController
  before_action :set_blog, only: [:show, :update, :destroy]
  before_action :authorize_request

end