class Wizard < ApplicationRecord
  require 'net/http'
  require "google/cloud/storage"
  require "pry"
  require 'fileutils'

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
end
