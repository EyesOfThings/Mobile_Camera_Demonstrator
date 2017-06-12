class HomeController < ApplicationController
  require 'json'
  require 'open-uri'
  require 'uri'
  require 'rest_client'
  require 'filesize'

  def show
    @current_user = current_user

    @auth_data = {
            'apiKey' => ENV["apiKey"],
            'authDomain' => ENV["authDomain"],
            'databaseURL' => ENV["databaseURL"],
            'storageBucket' => ENV["storageBucket"]
          }
  end

  def integrations
    @current_user = current_user

    @auth_data = {
            'apiKey' => ENV["apiKey"],
            'authDomain' => ENV["authDomain"],
            'databaseURL' => ENV["databaseURL"],
            'storageBucket' => ENV["storageBucket"]
          }
  end

  def wizards
    @current_user = current_user

    @auth_data = {
            'apiKey' => ENV["apiKey"],
            'authDomain' => ENV["authDomain"],
            'databaseURL' => ENV["databaseURL"],
            'storageBucket' => ENV["storageBucket"]
          }
  end

  def notifications
    @current_user = current_user

    @auth_data = {
            'apiKey' => ENV["apiKey"],
            'authDomain' => ENV["authDomain"],
            'databaseURL' => ENV["databaseURL"],
            'storageBucket' => ENV["storageBucket"]
          }
  end

  def animations
    @current_user = current_user

    @auth_data = {
            'apiKey' => ENV["apiKey"],
            'authDomain' => ENV["authDomain"],
            'databaseURL' => ENV["databaseURL"],
            'storageBucket' => ENV["storageBucket"]
          }
  end

  def save_animation_path
    @animation =  Animation.find(params['animation_id'])
    @animation.user_email = params['user_email']
    @animation.path = params['path']
    @animation.image_count = params['image_count']
    @animation.progress = 3
    @animation.save
  end

  def load_animation_path
    @animations = Animation.where(user_email: params['user_email'])
    render json: @animations.to_json.html_safe
  end

  def create_animation
    directory_name = DateTime.now.to_i
    @animation = Animation.new
    @animation.user_email = "#{params['user_email']}"
    @animation.name = params["animation_name"]
    @animation.progress = 1
    @animation.unix_time = directory_name
    @animation.save
    # directory_name = DateTime.now.to_i
    Dir.mkdir("#{directory_name}") unless File.exists?("#{directory_name}")
    all_images = params["image_paths"]
    count_image = 0
    all_images.each do |url|
      open("#{directory_name}/#{count_image}.jpg", 'wb') do |file|
        file << open(url).read
      end
      count_image += 1
    end
    begin
      system("cat #{directory_name}/*.jpg | ffmpeg -f image2pipe -r 1 -vcodec mjpeg -i - -vcodec libx264 #{directory_name}/#{directory_name}.mp4")
      RestClient.post("#{ENV['seaweedFiler']}/#{params['user_email']}/",
        :name_of_file_param => File.new("#{directory_name}/#{directory_name}.mp4"))
      file_size = File.size("#{directory_name}/#{directory_name}.mp4")
      human_file_size = Filesize.from("#{file_size} b").pretty
      system("rm -rf #{directory_name}")
      @animation.path = "#{ENV['seaweedFiler']}/#{params['user_email']}/#{directory_name}.mp4"
      @animation.image_count = "#{count_image}"
      @animation.progress = 3
      @animation.file_size = "#{human_file_size}"
      @animation.save
      render json: @animation.to_json.html_safe
    rescue Exception => e
      render json: "0"
    end
  end

  def send_to_seaweedfs
    date = params[:timestamp].to_i
    year = Time.at(date).utc.strftime("%Y")
    month = Time.at(date).utc.strftime("%m")
    day = Time.at(date).utc.strftime("%d")
    hour = Time.at(date).utc.strftime("%H")
    minutes = Time.at(date).utc.strftime("%M")
    seconds = Time.at(date).utc.strftime("%S")

    file_name = "#{minutes}_#{seconds}_000.jpg"
    dir_name = params[:dir_name].tr(':', '').downcase
    begin
      open(file_name, 'wb') do |file|
        file << open(params[:url]).read
      end

      RestClient.post("#{ENV['seaweedFiler']}/#{dir_name}/snapshots/recordings/#{year}/#{month}/#{day}/#{hour}/",
        :name_of_file_param => File.new(file_name))
      File.delete(file_name)
      render json: "1"
    rescue Exception => e
      render json: e.to_json
    end
  end
end
