require 'spec_helper'

describe 'Paperclip::Storage::GoogleDrive' do
  before do
    rebuild_model storage: :google_drive,
      :google_drive_client_secret_path => "spec/support/client_secret.json",
      :styles => { :medium => "300x300" },
      :google_drive_options => {
        :application_name => 'test-app',
        :public_folder_id => '0B-GFJI5FWVGyQXFKRzkydldoalk',
        :path => proc { |style| "#{style}_#{id}_#{avatar.original_filename}" }
      }
    @dummy = Dummy.new
  end

  context ' GoogleDrive load and save and image' do
    it 'should upload an image' do
      VCR.use_cassette('upload_image') do
        file = File.new("spec/fixtures/image.png", 'rb')
        @dummy.avatar = file
        expect(@dummy.avatar).to_not be_blank
        expect(@dummy.avatar).to be_present
        expect(@dummy.save).to be true
        expect(@dummy.avatar.url).to be_present
      end
    end
  end
end