class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(image_id)
    image = Image.find(image_id)
    # Your image processing logic here
    image.process!
  end
end