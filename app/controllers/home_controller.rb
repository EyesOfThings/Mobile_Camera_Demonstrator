class HomeController < ApplicationController
  require 'json'
  require 'open-uri'
  require 'uri'
  require 'rest_client'
  require 'filesize'
  require 'streamio-ffmpeg'
  require "google/cloud/storage"
  require 'dropbox'

  def list_emotions
    emotions = ["Anger", "Disgust", "FaceDetected", "Fear", "Happiness", "LargeFaceDetected", "MotionDetected", "Neutral", "Sadness", "Surpise"]
    render json: {emotions: emotions}
  end

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

  def create_wizard
    @wizard =  Wizard.new
    @wizard.email = params['email']
    @wizard.state = params['state']
    @wizard.is_working = params['is_working']
    @wizard.run_count = 1
    @wizard.save
    render json: @wizard.to_json.html_safe
  end

  def update_wizards
    @wizard =  Wizard.find(params["id"])
    @wizard.is_working = params['is_working']
    @wizard.save
    render json: "0"
  end

  def delete_wizard
    @wizard =  Wizard.find(params["id"])
    @wizard.delete
    render json: "0"
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

  def feeds
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

  def load_public_animation_path
    @animations = Animation.where(user_email: params['user_email'], is_public: true, progress: 3)
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

  def change_animation_public
    @animation =  Animation.find(params['id'])
    @animation.is_public = params['is_public']
    @animation.save
    render json: "1"
  end

  def load_wizards
    @wizards = Wizard.all
    render json: @wizards.to_json.html_safe
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
      system("cat #{directory_name}/*.jpg | ffmpeg -f image2pipe -r 5 -vcodec mjpeg -i - -vcodec libx264 #{directory_name}/#{directory_name}.mp4")
      upload_to = "#{params['user_email']}/#{directory_name}.mp4"
      local_to = "#{directory_name}/#{directory_name}.mp4"
      save_animation_to_storage(upload_to, local_to)

      movie = FFMPEG::Movie.new("#{directory_name}/#{directory_name}.mp4")
      file_size = File.size("#{directory_name}/#{directory_name}.mp4")
      human_file_size = Filesize.from("#{file_size} b").pretty
      system("rm -rf #{directory_name}")
      @animation.path = "#{params['user_email']}/#{directory_name}.mp4"
      @animation.image_count = "#{count_image}"
      @animation.progress = 3
      @animation.file_size = "#{human_file_size}"
      @animation.fps = movie.frame_rate
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

  def send_to_db
    date = params[:timestamp].to_i
    year = Time.at(date).utc.strftime("%Y")
    month = Time.at(date).utc.strftime("%m")
    day = Time.at(date).utc.strftime("%d")
    hour = Time.at(date).utc.strftime("%H")
    minutes = Time.at(date).utc.strftime("%M")
    seconds = Time.at(date).utc.strftime("%S")

    file_name = "#{year}-#{month}-#{day}-#{hour}-#{minutes}_#{seconds}_000.jpg"
    dir_name = params[:dir_name].tr(':', '').downcase
    client = Dropbox::Client.new(params[:accessToken])
    begin
      open(file_name, 'wb') do |file|
        file << open(params[:url]).read
      end
      read_file = File.open(file_name, 'rb') { |file| file.read }
      client.upload("/#{dir_name}/#{file_name}", read_file)

      File.delete(file_name)
      render json: "1"
    rescue Exception => e
      render json: e.to_json
    end
  end

  def upload_feed_to_db
    client = Dropbox::Client.new(params[:tokenValue])
    params[:imagePaths].each do |url|
      begin
        parts = url.split(" ")
        file_name = "#{Time.now.to_i}.#{parts[1]}"
        open(file_name, 'wb') do |file|
          file << open(parts[0]).read
        end
        read_file = File.open(file_name, 'rb') { |file| file.read }
        client.upload("/#{params[:whoUserEmail]}/#{file_name}", read_file)

        File.delete(file_name)
      rescue Exception => e
        puts e
      end
    end
  end

  private

  def save_animation_to_storage(upload_to, local_path)
    project_id = "wearableeot-39e6a"
    key_file   = "service-account.json"
    storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file
    bucket  = storage.bucket "wearableeot-39e6a.appspot.com"
    file = bucket.create_file local_path, upload_to
    puts "Uploaded #{file.name}"
  end

  def get_signed_path(file_name)
    project_id = "wearableeot-39e6a"
    key_file   = "service-account.json"
    storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file
    bucket  = storage.bucket "wearableeot-39e6a.appspot.com"
    file    = bucket.file file_name
    file.signed_url
  end
end
