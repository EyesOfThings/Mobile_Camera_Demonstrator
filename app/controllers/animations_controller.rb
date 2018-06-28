class AnimationsController < ApplicationController

  swagger_controller :animations, "Animations"

  swagger_api :index do
    summary "Fetches all animations for a user."
    param :path, :email, :string, :required, "User email for whom you want to load all animations."
    response :ok, "Success"
    response :not_found, "Not Found"
  end

  def index
    @animations = Animation.where(user_email: params['email'])
    if @animations.count > 0
      all_animations = @animations.map do |animation|
        {
          name: animation.name,
          image_count: animation.image_count,
          fps: animation.fps,
          file_size: animation.file_size,
          unix_time: animation.unix_time,
          id: animation.id,
          path: get_signed_path(animation.path),
          is_public: animation.is_public,
          progress: animation.progress
        }
      end
    else
      all_animations = @animations
    end
    render json: all_animations.to_json.html_safe
  end

  swagger_api :public do
    summary "Fetches all public animations for a user."
    param :path, :email, :string, :required, "User email for whom you want to load all animations."
    response :ok, "Success"
    response :not_found, "Not Found"
  end

  def public
    @animations = Animation.where(user_email: params['email'], is_public: true, progress: 3)
    if @animations.count > 0
      all_animations = @animations.map do |animation|
        {
          name: animation.name,
          image_count: animation.image_count,
          fps: animation.fps,
          file_size: animation.file_size,
          unix_time: animation.unix_time,
          id: animation.id,
          path: get_signed_path(animation.path),
          is_public: animation.is_public,
          progress: animation.progress
        }
      end
    else
      all_animations = @animations
    end
    render json: all_animations.to_json.html_safe
  end
end