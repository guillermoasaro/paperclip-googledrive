require "paperclip/google_drive/rake"

namespace :google_drive do
  desc "Authorize Google Drive account: "
  task :authorize, [:client_secret_path, :application_name] do |t, args|
    client_secret_path = args[:client_secret_path]
    application_name = args[:application_name]
    Paperclip::GoogleDrive::Rake.authorize(client_secret_path, application_name)
  end
end

