require 'spec_helper'

describe 'Paperclip::Storage::GoogleDrive' do
  context 'Manage an image' do
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
        @dummy.update_column(:avatar_file_name, 'image.png')
        @dummy.update_column(:avatar_content_type, 'image/png')
        @dummy.update_column(:avatar_fingerprint, 'c5591c5ae4d01cae00d27b1cfb95fb2e')
        @dummy.destroy
        expect(@dummy.avatar_file_name).to eq nil
        expect(@dummy.avatar_content_type).to eq nil
        expect(@dummy.avatar_fingerprint).to eq nil
      end
    end
  end
  context 'Errors' do
    it 'raise an error when it is not passed a google_drive_client_secret_path option' do
       rebuild_model(
        storage: :google_drive,
        google_drive_client_secret_path: nil
      )
      expect{ Dummy.new.save }.to raise_error(ArgumentError, 'You must provide a valid google_drive_client_secret_path option')
    end

    it 'raise an error when it is not passed a ivalid google_drive_client_secret_path option' do
       rebuild_model(
        storage: :google_drive,
        google_drive_client_secret_path: 'path/to/nowhere.json',
        google_drive_options: {
          application_name: 'test-app',
          public_folder_id: 'folder-id',
        }
      )
      expect{ Dummy.new.save }.to raise_error(ArgumentError, 'Missing required client identifier.')
    end

    it 'raise an error when there is not passed a application_name option' do
      rebuild_model(
        storage: :google_drive,
        google_drive_client_secret_path: 'spec/support/client_secret.json',
        google_drive_options: {
          public_folder_id: 'folder-id',
          application_name: nil
        }
      )
      expect{ Dummy.new.save }.to raise_error(ArgumentError, 'You must specify the application_name option')
    end

    it 'raise an error when there is not passed a public_folder_id option' do
      rebuild_model(
        storage: :google_drive,
        google_drive_client_secret_path: 'spec/support/client_secret.json',
        google_drive_options: {
          application_name: 'test-app',
          public_folder_id: nil,
        }
      )
      expect{ Dummy.new.save }.to raise_error(ArgumentError, 'You must set the public_folder_id option')
    end
  end
end
