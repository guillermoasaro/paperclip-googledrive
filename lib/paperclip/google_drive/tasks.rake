require "paperclip/google_drive/rake"

namespace :google_drive do
  desc "Authorize Google Drive account: "
  task :authorize, [:client_secret_path, :credentials_path] do |t, args|
    client_secret_path = args[:client_secret_path]
    credentials_path = args[:credentials_path]
    Paperclip::GoogleDrive::Rake.authorize(client_secret_path, credentials_path)
  end
end

