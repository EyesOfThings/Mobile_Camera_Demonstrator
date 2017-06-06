class HomeController < ApplicationController
  require 'json'
  require 'open-uri'
  require 'uri'
  require 'rest_client'

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

  def create_animation
    directory_name = DateTime.now.to_i
    Dir.mkdir("#{directory_name}") unless File.exists?("#{directory_name}")
    pry
    all_images = params["image_paths"]
    count_image = 1
    all_images.each do |url|
      open("#{directory_name}/#{count_image}.jpg", 'wb') do |file|
        file << open(url).read
      end
      count_image += 1
    end
    # begin
    #   open(file_name, 'wb') do |file|
    #     file << open(params[:url]).read
    #   end

    #   RestClient.post("#{ENV['seaweedFiler']}/#{dir_name}/snapshots/recordings/#{year}/#{month}/#{day}/#{hour}/",
    #     :name_of_file_param => File.new(file_name))
    #   File.delete(file_name)
    #   render json: "1"
    # rescue Exception => e
    #   render json: e.to_json
    # end
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
