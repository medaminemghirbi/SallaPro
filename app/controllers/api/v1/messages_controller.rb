class Api::V1::MessagesController < ApplicationController
  before_action :set_user, only: %i[create]
  
  def download_image
    image = Message.find(params[:message_id]).images.find_by(id: params[:image_id])
    if image
      redirect_to rails_blob_path(image, disposition: "attachment")
    else
      render json: { error: 'Image not found' }, status: :not_found
    end
  end
  def index
    @messages = Message.current.order(created_at: :asc)
    render json: @messages.as_json(
      include: {
        sender: { methods: [:user_image_url] }
      },
      methods: [:message_image_urls]
    )
  end
  
  # POST /messages
def create
  @message = Message.new(message_params)

  if @message.save
    if params[:images].present?
      params[:images].each do |image|
        @message.images.attach(image)
      end
    end

    # Include message_image_urls in the response
    render json: {
      message: "Message created successfully",
      data: @message.as_json(
        include: {
          sender: { methods: [:user_image_url] }
        },
        methods: [:message_image_urls]
      )
    }, status: :created
  else
    render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
  end
end


  # DELETE /messages/1
  def destroy
    @message = Message.find(params[:id])
    @message.destroy
  end


  private

  def set_user
    @user = User.find(params[:message][:sender_id])
  end

  def message_params
    params.require(:message).permit(:body, :sender_id, images: [])
  end
end
