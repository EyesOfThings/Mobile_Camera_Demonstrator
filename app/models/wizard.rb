class Wizard < ApplicationRecord
  require 'net/http'

  def self.start
    path_jpegs = get_with_path(extract_images(fetch_database()))
    # store_json(get_with_path(extract_images(fetch_database())))
    # keys = compare_stored_and_new_hash(path_jpegs)
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

  def self.extract_wizard_state_from_db(path_jpegs, state_email)
    
  end
end
