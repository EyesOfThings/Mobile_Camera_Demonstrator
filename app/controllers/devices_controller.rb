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

  def test_ifttt
    req = request.headers["IFTTT-Service-key"]
    if req.nil? || req.empty? || req == 'INVALID'
      render json: {status: "error", code: 401, message: "item_id is required to make a purchase"}, status: 401
    else
      response.headers['IFTTT-Service-Key'] = 'FY2sF4lG7pKIqFhxGW5vd0w6ZLTcwAfBqVcDkUQ6bgBQzToj6OUuJbm5OvGozKfF'
      render json: {
                      "data": {
                        "samples": {
                          "triggers": {
                            "devices": {
                              "device_id": {
                                  "id": 1530889183,
                                  "Anger": 0,
                                  "Disgust": 0,
                                  "FaceDetected": 0,
                                  "Fear": 0,
                                  "Happiness": 0,
                                  "LargeFaceDetected": 0,
                                  "MotionDetected": 0,
                                  "Neutral": 0,
                                  "Sadness": 0,
                                  "Surprise": 0,
                                  "URL": "https://storage.googleapis.com/wearableeot-39e6a.appspot.com/images/1530889183.jpeg?GoogleAccessId=send-wizards-to-users%40wearableeot-39e6a.iam.gserviceaccount.com&Expires=1631823276&Signature=ZIT2tk2ReBBkhJ%2F5uvcdLYeqmMNq5OYgI6NKZ9HabKVT2EVcKdUrocV%2FNyH7GNYfcd2p4MTsl0Z9%2B%2FHZ9A0B5kK97kISDh5aZG58718VHR67C153kpDE7q1tHASMoBou8EiJDlVADFiqv2mEoNXBC%2BGPmcpR3IupX332QEdasdelJkW6%2Bbbu29KrC0czBt%2BQl5xZhcH5fH0FRKAoAgNTn2OxOZg3vEFYaXI9MNtQVMxLURZpj5zlwabFm%2B7HPrxnrbvpAxBVWmpUdLm4hlt5W%2BZ5FBKBQVPb92hosdLxLsACzMu8Vfz2xxLLJB2lRI0V448AffRJCY8mhF3akau3xA%3D%3D"
                              }
                            }
                          }
                        }
                      }
                    }
    end
  end

  def status_ifttt
    req = request.headers["IFTTT-Service-key"]
    if req.nil? || req.empty? || req == 'INVALID'
      render json: {status: "error", code: 401, message: "item_id is required to make a purchase"}, status: 401
    else
      response.headers['IFTTT-Service-Key'] = 'FY2sF4lG7pKIqFhxGW5vd0w6ZLTcwAfBqVcDkUQ6bgBQzToj6OUuJbm5OvGozKfF'
      render json: {
                      "data": {
                        "samples": {
                          "triggers": {
                            "devices": {
                              "device_id": {
                                  "id": 1530889183,
                                  "Anger": 0,
                                  "Disgust": 0,
                                  "FaceDetected": 0,
                                  "Fear": 0,
                                  "Happiness": 0,
                                  "LargeFaceDetected": 0,
                                  "MotionDetected": 0,
                                  "Neutral": 0,
                                  "Sadness": 0,
                                  "Surprise": 0,
                                  "URL": "https://storage.googleapis.com/wearableeot-39e6a.appspot.com/images/1530889183.jpeg?GoogleAccessId=send-wizards-to-users%40wearableeot-39e6a.iam.gserviceaccount.com&Expires=1631823276&Signature=ZIT2tk2ReBBkhJ%2F5uvcdLYeqmMNq5OYgI6NKZ9HabKVT2EVcKdUrocV%2FNyH7GNYfcd2p4MTsl0Z9%2B%2FHZ9A0B5kK97kISDh5aZG58718VHR67C153kpDE7q1tHASMoBou8EiJDlVADFiqv2mEoNXBC%2BGPmcpR3IupX332QEdasdelJkW6%2Bbbu29KrC0czBt%2BQl5xZhcH5fH0FRKAoAgNTn2OxOZg3vEFYaXI9MNtQVMxLURZpj5zlwabFm%2B7HPrxnrbvpAxBVWmpUdLm4hlt5W%2BZ5FBKBQVPb92hosdLxLsACzMu8Vfz2xxLLJB2lRI0V448AffRJCY8mhF3akau3xA%3D%3D"
                              }
                            }
                          }
                        }
                      }
                    }
    end
  end

  def ifttt_trigger
    if params.has_key?(:limit)
      limit = params[:limit].to_i
    else
      limit = 50
    end
    fields = params[:triggerFields]
    req = request.headers["IFTTT-Service-key"]
    if req.nil? || req.empty? || req == 'INVALID'
      render json: {"errors": [status: "error", code: 401, message: "ifttt id is required"]}, status: 401
    elsif fields.nil? || fields.empty?
      render json: {"errors": [status: "error", code: 400, message: "lost fields"]}, status: 400
    else
      project_id = "wearableeot-39e6a"
      key_file   = "service-account.json"
      storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file, timeout: 100000000
      bucket  = storage.bucket "wearableeot-39e6a.appspot.com"
      if params.has_key?(:device_id)
        device = params[:device_id]
      else
        device = "F0:C7:7F:B3:85:70"
      end
      all_data = get_all_data()
      all_keys = get_em(all_data)
      all_devices_for = all_keys.select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}

      all_devices_for.each do |device_id|
        puts "The current array item is: #{device_id}"
        if device == device_id
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
          if limit == 0
            render json: {"data": [] }
          else
            array = create_json_to_return_ifttt(results, bucket)
            data = array.sort_by { |e| e['timestamp'] }[0..limit - 1].reverse!
            render json: {"data": data}
          end
        end
      end
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

  def create_json_to_return_ifttt(jpegs_path, bucket)
    all_ids = jpegs_path.map {|key, value| key.to_i}
    all_tags = jpegs_path.map {|key, value| value["Tags"]}
    all_paths = jpegs_path.map {|key, value| value["Path"]}
    id_count = all_ids.count
    all_ids.map.with_index do |value, index|
      if all_tags[index]["Anger"] == 1
        emotion = "Anger"
      elsif all_tags[index]["Disgust"] == 1
        emotion = "Disgust"
      elsif  all_tags[index]["Fear"] == 1
        emotion = "Fear"
      elsif all_tags[index]["Happiness"] == 1
        emotion = "Happiness"
      elsif all_tags[index]["Neutral"] == 1
        emotion = "Neutral"
      elsif all_tags[index]["Sadness"] == 1
        emotion = "Sadness"
      elsif all_tags[index]["Fear"] == 1
        emotion = "Fear"
      else
        emotion = "Emotion not detected"
      end
      {
        "URL": get_signed_url(all_paths[index], bucket),
        "emotion": emotion,
        "meta": {
          "id": value,
          "timestamp": value
        }
      }
    end
  end
end
