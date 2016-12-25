require 'active_support/core_ext/hash/keys'
require 'active_support/inflector/methods'
require 'active_support/core_ext/object/blank'
require 'yaml'
require 'erb'

require 'google/apis/drive_v3'
require 'googleauth'
require 'paperclip/google_drive/session'

require 'fileutils'

module Paperclip
  module Storage
    # * self.extended(base) add instance variable to attachment on call
    # * url return url to show on site with style options
    # * path(style) return title that used to insert file to store or find it in store
    # * public_url_for title  return url to file if find by title or url to default image if set
    # * search_for_title(title) take title, search in given folder and if it finds a file, return id of a file or nil
    # * metadata_by_id(file_i get file metadata from store, used to back url or find out value of trashed
    # * exists?(style)  check either exists file with title or not
    # * default_image  return url to default url if set in option
    # * find_public_folder return id of Public folder, must be in options
    # return id of Public folder, must be in options
    # * file_title return base pattern of title or custom one set by user
    # * original_extension  return extension of file
    module GoogleDrive
      class << self
        def extended(base)
          check_gem_is_installed
          base.instance_eval do
            @google_drive_client_secret_path = @options[:google_drive_client_secret_path]
            @google_drive_options = @options[:google_drive_options] || { application_name: 'test-app' }
            raise(ArgumentError, 'You must provide a valid google_drive_client_secret_path option') unless @google_drive_client_secret_path
            raise(ArgumentError, 'You must set the public_folder_id option') unless @google_drive_options[:public_folder_id]
            google_api_client # Force validations of credentials
          end
        end

        def check_gem_is_installed
          begin
            require 'google-api-client'
          rescue LoadError => e
            e.message << '(You may need to install the google-api-client gem)'
            raise e
          end unless defined?(Google)
        end
      end

      # Main process to upload a file
      def flush_writes
        @queued_for_write.each do |style, file|
          raise FileExists, "file \"#{path(style)}\" already exists in your Google Drive" if exists?(path(style))

          name, mime_type = name_for_file_from(style), "#{ file.content_type }"

          file_metadata = {
            name: name,
            description: 'paperclip file on google drive',
            mimeType: mime_type,
            parents: [find_public_folder]
          }

          google_api_client.create_file(
            file_metadata,
            fields: 'id',
            upload_source: file.binmode,
            content_type: file.content_type,
            )
        end
        after_flush_writes
        @queued_for_write = {}
      end

      # Process to destroy a file
      def flush_deletes
        @queued_for_delete.each do |path|
          Paperclip.log("Delete: #{ path }")
          file_id = search_for_title(path)
          google_api_client.delete_file(file_id) unless file_id.nil?
        end
        @queued_for_delete = []
      end

      # @return [ Google::Apis::DriveV3::DriveService ]
      def google_api_client
        @google_api_client ||= begin
          # Initialize the client & Google+ API
          ::Paperclip::GoogleDrive::Session.from_config(
            @google_drive_client_secret_path,
            application_name: @google_drive_options[:application_name]
          )
        end
      end

      alias_method :google_drive, :google_api_client

      # This could be used to scale image as Google does. e.i. `<url>=s220`,
      # where 220 is the width in pixeles OR as Paperclip does.
      # @params args [ Array ]
      # @return [ String ]
      #  ex.
      #     1. If you want the medium version of your image (Paperclip way)
      #       some_model.avatar.url(:medium)
      #     2. If you want a custom version of your image/pdf (Google way)
      #       some_model.avatar.url(:custom, width: 500)
      def url(*args)
        if present?
          style = args.first.is_a?(Symbol) ? args.first : default_style
          options = args.last.is_a?(Hash) ? args.last : {}
          if style == :custom
            custom_width = options[:width] || 220
            file_name = name_for_file_from(default_style)
          else
            custom_width = nil
            file_name = name_for_file_from(style)
          end

          public_url_for(file_name, custom_width)
        else
          default_image
        end
      end

      # Gets full title/name
      # @param style [ String ]
      # @return [ String ]
      def name_for_file_from(style)
        file_name = instance.instance_exec(style, &file_title)
        style_suffix = (style != default_style ? "_#{style}" : "")
        if original_extension.present? && file_name =~ /#{original_extension}$/
          file_name.sub(original_extension, "#{style_suffix}#{original_extension}")
        else
          file_name + style_suffix + original_extension.to_s
        end
      end

      alias_method :path, :name_for_file_from

      # Gets the public url for a passed filename
      # @param title [ String ]
      # @param custom_width [ Integer ]
      # @return [ String ] with url
      def public_url_for(title, custom_width)
        searched_id = search_for_title(title) #return id if any or style
        if searched_id.nil? # it finds some file
          default_image
        else
          metadata = metadata_by_id(searched_id)
          custom_image_for(metadata.thumbnail_link, custom_width)
        end
      end

      # Retrieves the specific image with a custom size. It is resized by GDrive API if you
      # pass the :custom as style option. In other cases it removes the last parameter `=s220`
      # which is inchaged to do the scaling process.
      # @param drive_thumbnail_link [ String ]
      # @param custom_width [ Integer ]
      # @return [ String ]
      def custom_image_for(drive_thumbnail_link, custom_width=nil)
        file_url, current_width = drive_thumbnail_link.split(/=s/)
        new_file_url = if custom_width.nil?
                        file_url
                      else
                        "#{ file_url }=s#{ custom_width }"
                      end
      end

      # Takes the file title/name and search it in a given folder
      # If it finds a file, return id of a file or nil
      # @param name [ String ]
      # @return [ String ] or NilClass
      def search_for_title(name)
        raise 'You are trying to search a file with NO name' if name.nil? || name.empty?
        client = google_api_client
        result = client.list_files(page_size: 1,
                q: "name contains '#{ name }' and '#{ find_public_folder }' in parents",
                fields: 'files(id, name)'
                )
        if result.files.length > 0
          result.files[0].id
        else
          nil
        end
      end

      # Gets a file from GDrive
      # @parent file_id [ String ]
      # @return [ Google::Apis::DriveV3::File ]
      def metadata_by_id(file_id)
        if file_id.is_a? String
          client = google_api_client
          metadata = client.get_file(
                    file_id,
                    fields: 'id, name, thumbnailLink'
                    )
          validate_metadata(metadata)
          metadata
        end
      end

      # Raises an error in case that the Google Drive API does not response
      # with the minimum required information.
      # @params [ Google::Apis::DriveV3::File ]
      def validate_metadata(metadata)
        raise 'the file id was not retrieved' if metadata.id.nil?
        raise 'the file name was not retrieved' if metadata.name.nil?
        raise 'the file thumbnail_link was not retrieved' if metadata.thumbnail_link.nil?
      end

      # Checks if the image already exits
      # @param style [ String ]
      # @return [ Boolean ]
      def exists?(style = default_style)
        return false if not present?
        result_id = search_for_title(path(style))
        if result_id.nil?
          false
        else
          data = metadata_by_id(result_id)
          !data.trashed # if trashed -> not exists
        end
      end

      def default_image
        if @google_drive_options[:default_url] #if default image is set
          title = @google_drive_options[:default_url]
          searched_id = search_for_title(title) # id
          metadata = metadata_by_id(searched_id) unless searched_id.nil?
          custom_image_for(metadata.thumbnail_link)
        else
          'No picture' # ---- ?
        end
      end

      def find_public_folder
        if @google_drive_options[:public_folder_id].is_a? Proc
          instance.instance_exec(&@google_drive_options[:public_folder_id])
        else
          @google_drive_options[:public_folder_id]
        end
      end

      #
      # Error classes
      #

      class FileExists < ArgumentError
      end

      private

      def file_title
        return @google_drive_options[:path] if @google_drive_options[:path] #path: proc
        eval %(proc { |style| "\#{id}_\#{#{name}.original_filename}"})
      end

      # @return [String] with the extension of file
      def original_extension
        File.extname(original_filename)
      end
    end

  end

end
