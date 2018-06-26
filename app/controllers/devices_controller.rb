class DevicesController < ApplicationController

  swagger_controller :devices, "Devices"

  swagger_api :index do
    summary "Fetches all the devcies."
    response :ok, "Success"
  end

  def index
    render json: get_em(get_all_data()).select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}
  end

  swagger_api :emotions do
    summary "Fetches all the emotions."
    response :ok, "Success"
  end

  def emotions
    emotions = ["Anger", "Disgust", "FaceDetected", "Fear", "Happiness", "LargeFaceDetected", "MotionDetected", "Neutral", "Sadness", "Surpise"]
    render json: {emotions: emotions}
  end

  swagger_api :user_devices do
    summary "Fetches all devices for a user."
    param :path, :email, :string, :required, "User email from firebase tree. e.g abc@bcd|com."
    response :ok, "Success"
    response :not_found, "Not Found"
  end

  def user_devices
    all_data = get_all_data()
    all_keys = all_data.keys
    user = params[:email].gsub(".","|")
    user_from_tree = all_keys.select {|v| v == user}.first
    if user_from_tree == nil
      render json: {message: "#{user} not found."}
    else
      render json: all_data[user_from_tree].keys.select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}
    end
  end

  swagger_api :device_images do
    summary "Fetches all images for a device."
    param :path, :device_id, :string, :required, "Deivce Mac Address. e.g 54:98:C4:45."
    response :ok, "Success"
    response :not_found, "Not Found"
  end

  def device_images
    project_id = "wearableeot-39e6a"
    key_file   = "service-account.json"
    storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file, timeout: 100000000
    bucket  = storage.bucket "wearableeot-39e6a.appspot.com"
    device_id = params[:device_id]
    all_data = get_all_data()
    all_keys = get_em(all_data)
    all_devices_for = all_keys.select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}

    if all_devices_for.include? device_id
      get_all_emails = all_keys.select {|e| e =~/\A[\w+\-|]+@[a-z\d\-]+(\|[a-z]+)*\|[a-z]+\z/}
      all_devices_for_user = get_all_emails.map do |email|
        {
          user: email,
          devices: get_em(all_data[email]).select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}
        }
      end

      get_final_user_and_device = all_devices_for_user.map {|e| e[:devices].include?(device_id) ? [e[:user], device_id] : nil}
      get_final_user_and_device
      results = get_single_device(all_data, get_final_user_and_device.compact.flatten)
      render json: create_json_to_return(results, bucket)
    else
      render json: {message: "#{device_id} not found."}
    end
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

  def get_signed_url(file_name, bucket)
    begin
      file    = bucket.file file_name
      file.signed_url method: "GET", expires: 100000000
    rescue => e
      "no jpeg on storage."
    end
  end

  def get_single_device(json_data, user_device_id)
    json_data[user_device_id[0]][user_device_id[1]]["Images"].select { |key, value| value['Path'] }
  end

  def create_json_to_return(jpegs_path, bucket)
    all_ids = jpegs_path.map {|key, value| key.to_i}
    all_tags = jpegs_path.map {|key, value| value["Tags"]}
    all_paths = jpegs_path.map {|key, value| value["Path"]}
    id_count = all_ids.count
    all_ids.map.with_index do |value, index|
      {
        "id": value,
        "Anger": all_tags[index]["Anger"],
        "Disgust": all_tags[index]["Disgust"],
        "FaceDetected": all_tags[index]["FaceDetected"],
        "Fear": all_tags[index]["Fear"],
        "Happiness": all_tags[index]["Happiness"],
        "LargeFaceDetected": all_tags[index]["LargeFaceDetected"],
        "MotionDetected": all_tags[index]["MotionDetected"],
        "Neutral": all_tags[index]["Neutral"],
        "Sadness": all_tags[index]["Sadness"],
        "Surprise": all_tags[index]["Surprise"],
        "URL": get_signed_url(all_paths[index], bucket)
      }
    end
  end
end