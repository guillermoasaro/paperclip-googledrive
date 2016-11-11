require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

module Paperclip
  module GoogleDrive
    module Rake
      extend self

      ##
      # Ensure valid credentials, either by restoring from the saved credentials
      # files or intitiating an OAuth2 authorization. If authorization is required,
      # the user's default browser will be launched to approve the request.
      #
      # @param client_secret_path [ String ] with the location of the JSON file downloaded from Google console
      # @param credentials_path [ String ] with the location of the YAML file
      # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
      def authorize(client_secret_path, credentials_path)
        OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
        APPLICATION_NAME = 'Drive API'
        # SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY
        SCOPE = Google::Apis::DriveV3::AUTH_DRIVE


        FileUtils.mkdir_p(File.dirname(credentials_path))

        client_id = Google::Auth::ClientId.from_file(client_secret_path)
        token_store = Google::Auth::Stores::FileTokenStore.new(file: credentials_path)
        authorizer = Google::Auth::UserAuthorizer.new(
        client_id, SCOPE, token_store)

        user_id = 'default'
        credentials = authorizer.get_credentials(user_id)
        if credentials.nil?
          url = authorizer.get_authorization_url(
            base_url: OOB_URI)
          puts "Open the following URL in the browser and enter the " +
               "resulting code after authorization"
          puts url
          code = gets
          credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: OOB_URI)
        end
        # Initialize the API
        service = Google::Apis::DriveV3::DriveService.new
        service.client_options.application_name = APPLICATION_NAME
        service.authorization = credentials
        # List the 10 most recently modified files.
        response = service.list_files(page_size: 10,
                                      fields: 'nextPageToken, files(id, name)')
        puts 'Files:'
        puts 'No files found' if response.files.empty?
        response.files.each do |file|
          puts "#{file.name} (#{file.id})"
        end

#         puts 'Enter client ID:'
#         client_id = $stdin.gets.chomp
#         puts 'Enter client SECRET:'
#         client_secret = $stdin.gets.chomp.strip
# #        puts 'Enter SCOPE:'
# #        oauth_scope = $stdin.gets.chomp.strip
#         oauth_scope = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/userinfo.profile']
#         puts 'Enter redirect URI:'
#         redirect_uri = $stdin.gets.chomp.strip

#         # Create a new API client & load the Google Drive API
#         client = Google::APIClient.new(:application_name => 'ppc-gd', :application_version => PaperclipGoogleDrive::VERSION)
#         drive = client.discovered_api('drive', 'v2')

#         client.authorization.client_id = client_id
#         client.authorization.client_secret = client_secret
#         client.authorization.scope = oauth_scope
#         client.authorization.redirect_uri = redirect_uri

#         # Request authorization
#         uri = client.authorization.authorization_uri.to_s
#         puts "\nGo to this url:"
#         puts client.authorization.authorization_uri.to_s
#         puts "\n Accept the authorization request from Google in your browser"

#         puts "\n\n\n Google will redirect you to localhost, but just copy the code parameter out of the URL they redirect you to, paste it here and hit enter:\n"

#         code = $stdin.gets.chomp.strip
#         client.authorization.code = code
#         client.authorization.fetch_access_token!

#         puts "\nAuthorization completed.\n\n"
#         puts "client = Google::APIClient.new"
#         puts "client.authorization.client_id = '#{client_id}'"
#         puts "client.authorization.client_secret = '#{client_secret}'"
#         puts "client.authorization.access_token = '#{client.authorization.access_token}'"
#         puts "client.authorization.refresh_token = '#{client.authorization.refresh_token}'"
#         puts "\n"
      end
    end
  end
end