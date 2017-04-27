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

  def send_to_seaweedfs
    begin
      open("#{params[:timestamp]}.jpg", 'wb') do |file|
        file << open(params[:url]).read
      end

      RestClient.post("#{ENV['seaweedFiler']}/#{params[:dir_name]}/snapshots/recordings/",
        :name_of_file_param => File.new("#{params[:timestamp]}.jpg"))
      File.delete("#{params[:timestamp]}.jpg")
      render json: "1"
    rescue Exception => e
      render json: e.to_json
    end
  end
end
