# Author: Hiroshi Ichikawa <http://gimite.net/>
# The license of this source is "New BSD Licence"
require 'google/apis/drive_v3'
require 'googleauth'
require 'paperclip/google_drive/config'
require 'fileutils'

module Paperclip
  module GoogleDrive
    # A session for Google Drive operations.
    #
    # Use from_credentials, from_access_token, from_service_account_key or from_config
    # class method to construct a Paperclip::GoogleDrive::Session object.
    class Session

      DEFAULT_SCOPE = Google::Apis::DriveV3::AUTH_DRIVE

      # Returns Google::Apis::DriveV3::DriveService constructed from a config JSON file at +config+.
      #
      # +config+ is the path to the config file.
      #
      # This will prompt the credential via command line for the first time and save it to
      # +config+ for later usages.
      #
      # See https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md for a usage example.
      #
      # You can also provide a config object that must respond to:
      #   client_id
      #   client_secret
      #   refesh_token
      #   refresh_token=
      #   scope
      #   scope=
      #   save
      def self.from_config(config, options = {})
        fail(ArgumentError, 'You must to specified the application_name option') unless options[:application_name]

        if config.is_a?(String)
          config = Paperclip::GoogleDrive::Config.new(config)
        end

        config.scope ||= DEFAULT_SCOPE

        if options[:client_id] && options[:client_secret]
          config.client_id = options[:client_id]
          config.client_secret = options[:client_secret]
        elsif (options[:client_id] && !options[:client_secret]) ||
                (!options[:client_id] && options[:client_secret])
          fail(ArgumentError, 'client_id and client_secret must be both specified or both omitted')
        end

        credentials = Google::Auth::UserRefreshCredentials.new(
          client_id: config.client_id,
          client_secret: config.client_secret,
          scope: config.scope,
          redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')

        if config.refresh_token
          credentials.refresh_token = config.refresh_token
          credentials.fetch_access_token!
        else
          $stderr.print("\n1. Open this page:\n%s\n\n" % credentials.authorization_uri)
          $stderr.print('2. Enter the authorization code shown in the page: ')
          credentials.code = $stdin.gets.chomp
          credentials.fetch_access_token!
          config.refresh_token = credentials.refresh_token
        end

        config.save

        # Initialize the API
        client = Google::Apis::DriveV3::DriveService.new
        client.client_options.application_name = options[:application_name]
        client.authorization = credentials
        client
      end
    end
  end
end