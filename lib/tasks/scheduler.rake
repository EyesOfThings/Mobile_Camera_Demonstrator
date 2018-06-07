task :send_wizards => :environment do
  Wizard.start
  Wizard.on_click_create
end