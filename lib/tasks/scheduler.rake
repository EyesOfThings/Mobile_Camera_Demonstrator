task :send_wizards => :environment do
  Wizard.on_click_create
  Wizard.start
end