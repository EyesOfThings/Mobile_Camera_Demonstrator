task :send_wizards => :environment do
  Wizard.start
end