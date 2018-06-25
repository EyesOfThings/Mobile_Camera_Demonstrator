class Wizard < ApplicationRecord
  require 'net/http'
  require "google/cloud/storage"
  require "pry"
  require 'fileutils'
  require 'json'
  require 'open-uri'
  require 'uri'
  require 'rest_client'
  require 'filesize'
  require 'streamio-ffmpeg'
  require "google/cloud/storage"
  require 'dropbox'

  def self.new_device_detected
    all_data = get_all_data()
    get_all_keys = get_keys(all_data)
    get_all_emails = get_all_keys.select {|e| e =~/\A[\w+\-|]+@[a-z\d\-]+(\|[a-z]+)*\|[a-z]+\z/}

    fetch_emails_with_new_devices = get_all_emails.map do |email|
      all_devices_for_user = get_keys(all_data[email]).select {|e| e =~/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/}
      bool, macs = compare_to_old_device_if_new_save(all_devices_for_user, email)
      if bool == true
        {
          email: email,
          devices: macs
        }
      end
    end
    get_emails_creds = fetch_emails_with_new_devices.compact.each do |user|
      user[:creds] = get_sync_creds(all_data, user[:email])
    end

    project_id = "wearableeot-39e6a"
    key_file   = "service-account.json"
    storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file
    bucket  = storage.bucket "wearableeot-39e6a.appspot.com"

    get_emails_creds.each do |an_object|
      an_object[:devices].flatten.each do |device|
        jpegs_with_path = get_with_path(extract_images(fetch_database(an_object[:email].gsub("|","%7C")), device)).map { |key, value| value["Path"] }
        client = Dropbox::Client.new(an_object[:creds][:dropboxToken])
        send_jpegs_to_evercam_dropbox(jpegs_with_path, bucket, an_object[:email], client)
      end
    end
  end

  def self.send_jpegs_to_evercam_dropbox(jpegs_with_path, bucket, email, client)
    jpegs_with_path.each do |file_name|
      begin
        date = file_name.gsub(/[^0-9]/, '').to_i
        year = Time.at(date).utc.strftime("%Y")
        month = Time.at(date).utc.strftime("%m")
        day = Time.at(date).utc.strftime("%d")
        hour = Time.at(date).utc.strftime("%H")
        minutes = Time.at(date).utc.strftime("%M")
        seconds = Time.at(date).utc.strftime("%S")

        file_evercam = "#{minutes}_#{seconds}_000.jpg"
        file_dropbox = "#{year}-#{month}-#{day}-#{hour}-#{minutes}_#{seconds}_000.jpg"
        file = bucket.file file_name
        file.download file_evercam
        dir_name = "ever-#{email[0..3]}"
        db_dir_name = "db-#{email[0..3]}"

        begin
          read_file = File.open(file_evercam, 'rb') { |file| file.read }
          client.upload("/#{db_dir_name}/#{file_dropbox}", read_file)
          RestClient.post("#{ENV['seaweedFiler']}/#{dir_name}/snapshots/recordings/#{year}/#{month}/#{day}/#{hour}/", :name_of_file_param => File.new(file_evercam))
          File.delete(file_evercam)
        rescue => e
          puts "seems like an error on seaweedFiler #{e}"
        end
      rescue => e
        puts "File not found."
      end
    end
  end

  def self.get_sync_creds(all_data, email)
    {
      apiKey: all_data[email]["evercam"]["syncIsOn"] == "1" ? all_data[email]["evercam"]["apiKey"] : nil,
      apiId: all_data[email]["evercam"]["syncIsOn"] == "1" ? all_data[email]["evercam"]["apiId"] : nil,
      dropboxToken: all_data[email]["dropbox"]["syncIsOn"] == "1" ? all_data[email]["dropbox"]["accessToken"] : nil
    }
  end

  def self.compare_to_old_device_if_new_save(all_devices_for_user, email)
    begin
      old_devices = JSON.parse(File.read("#{email}_devices.json"))
      if all_devices_for_user == old_devices
        puts "there is no new device to save for #{email}"
        [false, []]
      else
        File.open("#{email}_devices.json", "w") do |f|
          f.write(all_devices_for_user.to_json)
        end
        [true, [all_devices_for_user + old_devices - (all_devices_for_user & old_devices)]]
      end
    rescue => e
      puts "Error opening past files, user must be new one #{email}."
      File.open("#{email}_devices.json", "w") do |f|
        f.write(all_devices_for_user.to_json)
      end
      [true, all_devices_for_user]
    end
  end

  def self.get_keys(h)
    h.each_with_object([]) do |(k,v),keys|      
      keys << k
      keys.concat(get_keys(v)) if v.is_a? Hash
    end
  end

  def self.start
    states = get_working_wizards_states
    states.each do |state|
      path_jpegs = get_with_path(extract_images(fetch_database(state[:email_tree]), state[:mac]))
      new_jpegs = compare_stored_and_new_hash(path_jpegs, state[:mac])
      if new_jpegs.length > 0
        store_json(path_jpegs, state[:mac])
        new_path_jpegs = path_jpegs.select { |k, _| new_jpegs.include? k }

        jpegs_only = extract_wizard_state_from_db(new_path_jpegs, [state])
        get_jpegs_from_state_and_email(jpegs_only)
      else
        puts "Nothing new found."
      end
    end
  end

  def self.on_click_create
    wizards = get_first_run_wizards
    if wizards != []
      wizards.each do |wizard|
        paths = get_with_path(extract_images(fetch_database(wizard[:email_tree]), wizard[:mac]))
        store_json(paths, wizard[:mac])
        jpegs_only = extract_wizard_state_from_db(paths, [wizard])
        get_jpegs_from_state_and_email(jpegs_only)
        update_run_count_wizards()
      end
    else
      puts "No Newly created Wizards"
    end
  end

  def self.fetch_database(email_tree)
    result = Net::HTTP.get(URI.parse("https://wearableeot-39e6a.firebaseio.com/#{email_tree}.json?auth=#{ENV['auth']}"))
    JSON.parse result
  end

  def self.extract_images(json, mac)
    json["#{mac}"]["Images"]
  end

  def self.get_with_path(images)
    images.select { |key, value| value['Path'] }
  end

  def self.store_json(json, mac)
    File.open("#{mac}.json", "w") do |f|
      f.write(json.to_json)
    end
  end

  def self.get_first_run_wizards
    Wizard.where(is_working: true, run_count: 1).map do |wizard|
      {
        state: wizard.state,
        email: wizard.email,
        email_tree: wizard.email_tree,
        mac: wizard.mac
      }
    end
  end

  def self.update_run_count_wizards
    Wizard.where(run_count: 1).update_all(run_count: 2)
  end

  def self.get_working_wizards_states
    Wizard.where(is_working: true, run_count: 2).map do |wizard|
      {
        state: wizard.state,
        email: wizard.email,
        email_tree: wizard.email_tree,
        mac: wizard.mac
      }
    end
  end

  def self.compare_stored_and_new_hash(new_hash, mac)
    stored_hash = JSON.parse(File.read("#{mac}.json"))
    stored_hash.merge(new_hash){ |k, v1, v2| v1 == v2 ? :equal : [v1, v2] }.reject { |_, v| v == :equal }.keys
  end

  def self.extract_wizard_state_from_db(path_jpegs, state_and_email)
    state_and_email.map do |wiz|
      {
        state_object: fetch_path_from_state(path_jpegs.select { |key, value| value['Path'] && value['Tags'] && (value['Tags'][wiz[:state]] == 1)}),
        email: wiz[:email],
        emotion: wiz[:state]
      }
    end
  end

  def self.fetch_path_from_state(state_object)
    state_object.map { |key, value| value["Path"] }
  end

  def self.get_jpegs_from_state_and_email(jpeg_objects_and_emails)
    project_id = "wearableeot-39e6a"
    key_file   = "service-account.json"
    storage = Google::Cloud::Storage.new project: project_id, keyfile: key_file
    bucket  = storage.bucket "wearableeot-39e6a.appspot.com"
    FileUtils::mkdir_p("images")
    jpeg_objects_and_emails.each do |objective|
      if objective[:state_object] == []
        puts "has nothing to do."
      else
        objective[:state_object].each do |file_name|
          file = bucket.file file_name
          file.download file_name
          puts "Downloaded #{file.name}"
        end
        send_email_with_attach(objective[:state_object], objective[:email], objective[:emotion])
      end
    end
    FileUtils.rm_rf('images')
  end

  def self.send_email_with_attach(jpeg_paths, email, emotion)
    data = {}
    data[:from] = "Eyes Of Things <support@evercam.io>"
    data[:to] = "#{email}"
    data[:subject] = "This is getting emotional: 😀😓😡🙂😥😝."
    data[:text] = "Your Wizard has been arrived!"
    data[:html] = "<html>EoT found the following images that match your settings: Emotion = #{emotion} (See Attached). <br><br> To change your settings, click <a href='http://eot.evercam.io/wizards'>here</a></html>"
    data[:attachment] = []
    jpeg_paths.each do |file_path|
      data[:attachment] << File.new(file_path)
    end
    puts data
    begin
      puts "sending_email"
      RestClient.post "https://api:#{ENV['mailgun_key']}"\
          "@#{ENV['mailgun_domain']}", data
    rescue RestClient::ExceptionWithResponse => e
      puts e.response
    end
  end

  def self.get_all_data
    result = Net::HTTP.get(URI.parse("https://wearableeot-39e6a.firebaseio.com/.json?auth=#{ENV['auth']}"))
    JSON.parse result
  end
end
