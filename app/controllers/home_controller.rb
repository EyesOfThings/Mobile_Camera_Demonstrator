class HomeController < ApplicationController
  require 'json'
  require 'open-uri'

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
    open('image.jpg', 'wb') do |file|
      file << open(params[:url]).read
    end

    require 'uri'
    require 'base64'
    require 'net/http'
    require 'net/https'

    img_file = "my_img.jpg"
    img_url = "www.my_url.com/img/receive_images_contr_method?id_my_img=1"
    url = URI.parse(img_url)
    file = open(img_file)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url.path + '?' + url.query)
    request.body = Base64.encode64(file.read)
    request["Content-Type"] = "text/plain"
    response = http.request(request)
    response.code
    response.body
    file.close
  end
end
