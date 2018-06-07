class Wizard < ApplicationRecord
  require 'net/http'
  require "google/cloud/storage"
  require "pry"
  require 'fileutils'

  def self.start
    path_jpegs = get_with_path(extract_images(fetch_database()))
    new_jpegs = compare_stored_and_new_hash(path_jpegs)
    if new_jpegs.length > 0
      store_json(path_jpegs)
      new_path_jpegs = path_jpegs.select { |k, _| new_jpegs.include? k }
      states = get_working_wizards_states
      jpegs_only = extract_wizard_state_from_db(new_path_jpegs, states)
      get_jpegs_from_state_and_email(jpegs_only)
    end
  end

  def self.on_click_create(wizard)
    paths = get_with_path(extract_images(fetch_database()))
    jpegs_only = extract_wizard_state_from_db(paths, wizard)
    get_jpegs_from_state_and_email(jpegs_only)
  end

  def self.fetch_database
    result = Net::HTTP.get(URI.parse("https://wearableeot-39e6a.firebaseio.com/visilabeot@gmail%7Ccom.json?auth=#{ENV['auth']}"))
    JSON.parse result
  end

  def self.extract_images(json)
    json["D0:5F:B8:4D:3B:58"]["Images"]
  end

  def self.get_with_path(images)
    images.select { |key, value| value['Path'] }
  end

  def self.store_json(json)
    File.open("temp.json", "w") do |f|
      f.write(json.to_json)
    end
  end

  def self.get_working_wizards_states
    Wizard.where(is_working: true).map do |wizard|
      {
        state: wizard.state,
        email: wizard.email
      }
    end
  end

  def self.compare_stored_and_new_hash(new_hash)
    stored_hash = JSON.parse(File.read('temp.json'))
    stored_hash.merge(new_hash){ |k, v1, v2| v1 == v2 ? :equal : [v1, v2] }.reject { |_, v| v == :equal }.keys
  end

  def self.extract_wizard_state_from_db(path_jpegs, state_and_email)
    state_and_email.map do |wiz|
      {
        state_object: fetch_path_from_state(path_jpegs.select { |key, value| value['Path'] && value['Tags'] && (value['Tags'][wiz[:state]] == 1)}),
        email: wiz[:email]
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
        send_email_with_attach(objective[:state_object], objective[:email])
      end
    end
    FileUtils.rm_rf('images')
  end

  def self.send_email_with_attach(jpeg_paths, email)
    data = {}
    data[:from] = "Eyes Of Things <support@evercam.io>"
    data[:to] = "#{email}"
    data[:subject] = "Eyes Of Things."
    data[:text] = "Your Wizard has been arrived!"
    data[:html] = "<html>Your Wizard has been arrived.</html>"
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
end
