class DevicesController < ApplicationController

  swagger_controller :devices, "Devices"

  swagger_api :index do
    summary "Fetches all the devcies."
    response :ok, "Success"
  end

  def index
    render json: get_em(get_all_data()).select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}
  end

  private

  def get_all_data
    result = Net::HTTP.get(URI.parse("https://wearableeot-39e6a.firebaseio.com/.json?auth=#{ENV['auth']}"))
    JSON.parse result
  end

  def get_em(h)
    h.each_with_object([]) do |(k,v),keys|      
      keys << k
      keys.concat(get_em(v)) if v.is_a? Hash
    end
  end
end