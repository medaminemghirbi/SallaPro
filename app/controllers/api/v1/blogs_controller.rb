class Api::V1::BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :update, :destroy]
  before_action :authorize_request, only: [:create, :update, :destroy]
  # GET /api/v1/blogs
  def index
    blogs = Blog.order(:order).current.includes(:doctor, :maladie).as_json(
      methods: [:image_urls],
      include: {
        doctor: {
          methods: [:user_image_url]
        },
        maladie: {} # Ensure you include the `maladie` association
      }
    )
    render json: blogs, status: :ok
  end
  
  def verified_blogs
    blogs = Blog.current.verified.order(:order).current.includes(:doctor, :maladie).as_json(
      methods: [:image_urls],
      include: {
        doctor: {
          methods: [:user_image_url]
        },
        maladie: {} # Ensure you include the `maladie` association
      }
    )
    render json: blogs, status: :ok
  end
  
  
  def my_blogs
    blogs = Blog.where(doctor_id: params[:doctor_id]).order(:order).current.includes(:doctor, :maladie).as_json(
      methods: [:image_urls],
      include: {
        doctor: {
          methods: [:user_image_url]
        },
        maladie: {}
      }
    )
    render json: blogs, status: :ok
  end
  # GET /api/v1/blogs/:id
  def show
    render json: @blog.as_json(
      methods: [:image_urls],
      include: {
        doctor: {
          methods: [:user_image_url]
        },
        maladie: {} # Ensure you include the `maladie` association
      }
    ), status: :ok
  end
  
  # POST /api/v1/blogs
  def create
    blog = Blog.new(blog_params)
    blog.doctor = Doctor.find params[:doctor_id]
    if blog.save
      render json: blog, status: :created
    else
      render json: { errors: blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/blogs/:id
  def destroy
    @blog.update(is_archived: true)
    render json: { message: 'Blog archived successfully' }, status: :ok
  end

  def update
    # Only allow `is_verified` to be updated if included in the request
    if @blog.update(blog_update_params)
      render json: @blog
    else
      render json: @blog.errors, status: :unprocessable_entity
    end
  end

  def all_all_verification
    if Blog.update_all(is_verified: true)
      render json: { message: "All blogs have been verified." }, status: :ok
    else
      render json: { error: "Failed to verify all blogs." }, status: :unprocessable_entity
    end
  end
  
  private

  def set_blog
    @blog = Blog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Blog not found' }, status: :not_found
  end

  def blog_params
    params.permit(:title, :content, :maladie_id, :doctor_id, images: [])
  end

  def blog_update_params
    params.permit( :is_verified)
  end
end