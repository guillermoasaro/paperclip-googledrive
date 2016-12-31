# PaperclipGoogleDrive
[![GitHub version](https://badge.fury.io/gh/degzcs%2Fpaperclip-googledrive.svg)](https://badge.fury.io/gh/degzcs%2Fpaperclip-googledrive)
[![Code Climate](https://codeclimate.com/github/degzcs/paperclip-googledrive/badges/gpa.svg)](https://codeclimate.com/github/degzcs/paperclip-googledrive)

PaperclipGoogleDrive is a gem that extends paperclip storage for Google Drive (V3). Works with Rails 3.x. and later.
IMPORTANT NOTE: This repo was forked and upgraded to use Google Drive V3.

## Installation

Add this line to your application's Gemfile:

    gem 'paperclip-google-drive'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperclip-google-drive

## Google Drive Setup

Google Drive is a free service for file storage files. In order to use this storage you need a Google (or Google Apps) user which will own the files, and a Google API client.

1. Go to the [Google Developers console](https://console.developers.google.com/project) and create a new project, this option is on the top, next to the Google APIs logo.

2. Go to "API Manager > Library" in the section "Google Apps APIs" and enable "Drive API". If you are getting an "Access Not Configured" error while uploading files, this is due to this API not being enabled.

3. Go to "API Manager > Credentials" and click on "OAuth Client ID" before to select "Other" type you must specify `http://localhost` for application home page.

4. Now you will have a Client ID, Client Secret, and Redirect URL. So, download the client_secret_XXXXX.json file and rename it to client_secret.json.

5. Run the authorization task:
    ```sh
    $ rake google_drive:authorize"[path/to/client_secret.json, 'application_name']"
    ```
    NOTE:
     - the `path/to/client_secret.json` path is the file downloaded from Google console (it will be overrided with the fresh token).
     - the `application_name` param is the name that you set for the application credentials on Google console.

6. The Rake task will give you an auth url. Simply go to that url (while signed in as the designated uploads owner), authorize the app, then enter code from url in the console. The rake task will override valid `client_secret.json` which you can use to connect with GoogleDrive from now on.

7. Create a folder in which the files will be uploaded; note the folder's ID.

## Configuration

Example:
```ruby
class Product < ActiveRecord::Base
 has_attached_file :photo,
    :storage => :google_drive,
    :google_drive_client_secret_path => "#{Rails.root}/config/client_secret.json"
end
```
The `:google_drive_client_secret_path` option

This is the path of the file which was obtained from your Google Drive app settings and the authorization Rake task.

Example of the overridden `path/to/client_secret.json` file:
```json
{
  "client_id": "4444-1111.apps.googleusercontent.com",
  "client_secret": "1yErh1pR_7asdf8tqdYM2LcuL",
  "scope": "https://www.googleapis.com/auth/drive",
  "refresh_token": "1/_sVZIgY5thPetbWDTTTasdDID5Rkvq6UEfYshaDs5dIKoUAKgjE9f"
}
```
It is good practice to not include the credentials directly in the JSON file. Instead you can set them in environment variables and embed them with ERB.

## Options

The `:google_drive_options` option

This is a hash containing any of the following options:
 - `:path` – block, works similarly to Paperclip's `:path` option
 - `:public_folder_id`- id of folder that must be created in google drive and set public permissions on it
 - `:default_image` - an image in Public folder that used for attachments if attachment is not present
 - `:application_name` - is the name that you set for the application credentials on Google console.

The :path option should be a block that returns a path that the uploaded file should be saved to. The block yields the attachment style and is executed in the scope of the model instance. For example:

```ruby
class Product < ActiveRecord::Base
  has_attached_file :photo,
    :storage => :google_drive,
    :google_drive_client_secret_path => "#{Rails.root}/config/client_secret.json"
    :styles => { :medium => "300x300" },
    :google_drive_options => {
      :path => proc { |style| "#{id}_#{photo.original_filename}_#{style}" },
      :public_folder_id => 'AAAARRRRGGGBBBFFFFadsasdX'
    }
end
```
For example, a new product is created with the ID of 14, and a some_photo.jpg as its photo. The following files would be saved to the Google Drive:

```
Public/14_some_photo.jpg
Public/14_some_photo_medium.jpg
```

The another file is called some_photo_medium.jpg because style names (other than original) will always be appended to the filenames, for better management.

Also, you can use the resize feature provided by GDrive API, you only have to pass as parameter in the url params the option `:custom_thumb` and `:width`, as follows:

```ruby
  some_product.photo.url(:custom_thumb, width: 500)
```

## Example App

You can find an example of how to config a Rails project [here](https://github.com/degzcs/rails-paperclip-gdrive-example)

## Issues

### Non image files Issues (PDF, CSV, etc)

I still working on retrieve the raw files, I would like to get the files as `thumbnail_link` file attribute does, but it is not that easy, because Google Drive API has some retrictions. So, all non image files are shown in Google Drive viewer.

## Useful links

[Google APIs console](https://code.google.com/apis/console/)

[Google Drive scopes](https://developers.google.com/drive/scopes)

[Enable the Drive API and SDK](https://developers.google.com/drive/enable-sdk)

[Quickstart](https://developers.google.com/drive/v3/web/quickstart/ruby)

## License

[MIT License](https://github.com/degzcs/paperclip-googledrive/blob/master/LICENSE)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
