require 'spec_helper'

describe 'Paperclip::Storage::GoogleDrive' do
  before do
    rebuild_model(
      storage: :google_drive,
      google_drive_client_secret_path: 'spec/support/client_secret.json',
      styles: { medium: '300x300' },
      google_drive_options: {
        application_name: 'test-app',
        public_folder_id: '0B-GFJI5FWVGyQXFKRzkydldoalk',
        path: proc { |style| "#{style}_#{id}_#{avatar.original_filename}" }
      }
    )
    @dummy = Dummy.new
  end

  context ' GoogleDrive manage an image' do
    it 'should upload an image' do
      VCR.use_cassette('upload_image') do
        file = File.new('spec/fixtures/image.png', 'rb')
        @dummy.avatar = file
        expect(@dummy.avatar).to_not be_blank
        expect(@dummy.avatar).to be_present
        expect(@dummy.save).to be true
        expect(@dummy.avatar.url).to be_present
      end
    end

    it 'should destroy an image' do
       VCR.use_cassette('remove_image') do
        @dummy.save
        @dummy.update_column(:avatar_file_name, "image.png")
        @dummy.update_column(:avatar_content_type, "image/png")
        @dummy.update_column(:avatar_fingerprint, "c5591c5ae4d01cae00d27b1cfb95fb2e")
        @dummy.destroy
        expect(@dummy.avatar_file_name).to eq nil
        expect(@dummy.avatar_content_type).to eq nil
        expect(@dummy.avatar_fingerprint).to eq nil
      end
    end
  end
end
