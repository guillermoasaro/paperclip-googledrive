require 'spec_helper'

describe 'Paperclip::Storage::GoogleDrive' do
  before do
    rebuild_model storage: :google_drive,
      :google_drive_credentials_path => "spec/support/credentials.yml",
      :google_drive_client_secret_path => "spec/support/client_secret.json",
      :styles => { :medium => "300x300" },
      :google_drive_options => {
        :public_folder_id => '0B2FjTd4EiKiUNDRjQ3EzNU53cmc',
        :path => proc { |style| "#{style}_#{id}_#{avatar.original_filename}" }
      }
    @dummy = Dummy.new
  end

  context ' GoogleDrive client setup' do
    it 'shoould set up a client' do
      file = File.new("spec/fixtures/image.png", 'rb')
      @dummy.avatar = file
      expect(@dummy.avatar).to_not be_blank
      expect(@dummy.avatar).to be_present
      @dummy.save
      # binding.pry
      # 1
      # dummy_class
    end
  end
end