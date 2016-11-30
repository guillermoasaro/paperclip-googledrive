require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'pry'

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
      # @param credentials_path [ String ] with the location of the YAML file, this will be created for this task
      # @param application_name [ String ] given in the Google console > credentials > OAuth 2.0 client IDs section
      # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
      def authorize(client_secret_path, credentials_path, application_name)
        oob_uri= 'urn:ietf:wg:oauth:2.0:oob'
        # scope = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY
        scope = Google::Apis::DriveV3::AUTH_DRIVE

        FileUtils.mkdir_p(File.dirname(credentials_path))
        binding.pry
        client_id = Google::Auth::ClientId.from_file(client_secret_path)
        token_store = Google::Auth::Stores::FileTokenStore.new(file: credentials_path)
        authorizer = Google::Auth::UserAuthorizer.new(
        client_id, scope, token_store)

        user_id = 'default'
        credentials = authorizer.get_credentials(user_id)
        if credentials.nil?
          url = authorizer.get_authorization_url(base_url: oob_uri)
          puts "\nOpen the following URL in the browser and enter the " +
               "resulting code after authorization\n"
          puts url
          code = $stdin.gets.chomp.strip
          credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: oob_uri)
        end
        # Initialize the API
        client = Google::Apis::DriveV3::DriveService.new
        client.client_options.application_name = application_name
        client.authorization = credentials
        # # List the 10 most recently modified files.
        # response = client.list_files(page_size: 10,
        #                               fields: 'nextPageToken, files(id, name)')
        # puts 'Files:'
        # puts 'No files found' if response.files.empty?
        # response.files.each do |file|
        #   puts "#{file.name} (#{file.id})"
        # end

        puts "\nAuthorization completed.\n\n"
        puts "The credentials were saved into #{ credentials_path}.\n"
        puts "You can use these credentials as follows: \n"
        puts "client_id = Google::Auth::ClientId.from_file(client_secret_path)"
        puts "token_store = Google::Auth::Stores::FileTokenStore.new(file: credentials_path)"
        puts "authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)"
        puts "  client = Google::Apis::DriveV3::DriveService.new"
        puts "  credentials = authorizer.get_credentials('#{ user_id }')"
        puts "  client.client_options.application_name = '#{ application_name }'"
        puts "  client.authorization = credentials"
        puts "\n"
      end
    end
  end
end