# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'psych'

describe SessionAdapter do
  subject { described_class.new }
  let (:spec_session_path) { 'spec/tmp/.ccli/session' }
  let (:encoded_token) { Base64.encode64('bob:1234') }

  before(:each) do
    stub_const("SessionAdapter::FILE_LOCATION", spec_session_path)
  end

  context 'update session' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp'))
    end

    it 'writes new session file with correct data' do
      expect(File.exist?('../tmp/.ccli')).to be(false)

      subject.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      expect(File.exist?(File.expand_path(spec_session_path))).to be(true)

      file_data = Psych.load_file(File.expand_path(SessionAdapter::FILE_LOCATION))

      expect(file_data[:url]).to eq('https://cryptopus.example.com')
      expect(file_data[:username]).to eq('bob')
      expect(file_data[:token]).to eq('1234')
    end

    it 'overwrites existing session' do
      subject.update_session({ encoded_token: encoded_token, url: 'https://old.host.com' })

      encoded_token_new = Base64.encode64('carl:56789')

      subject.update_session({ encoded_token: encoded_token_new, url: 'https://new.host.com' })

      file_data = Psych.load_file(File.expand_path(SessionAdapter::FILE_LOCATION))

      expect(file_data[:url]).to eq('https://new.host.com')
      expect(file_data[:username]).to eq('carl')
      expect(file_data[:token]).to eq('56789')
    end

    it 'selects folder' do
      subject.update_session({ folder: 2})

      file_data = Psych.load_file(File.expand_path(SessionAdapter::FILE_LOCATION))

      expect(file_data[:folder]).to eq(2)
    end

    it 'selects folder after setting session' do
      subject.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      subject.update_session({ folder: 2})

      file_data = Psych.load_file(File.expand_path(SessionAdapter::FILE_LOCATION))

      expect(file_data[:folder]).to eq(2)
      expect(file_data[:url]).to eq('https://cryptopus.example.com')
      expect(file_data[:username]).to eq('bob')
      expect(file_data[:token]).to eq('1234')
    end
  end

  context 'clear session' do
    it 'deletes session data' do
      expect(File.exist?('../tmp/.ccli')).to be(false)

      subject.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      expect(File.exist?(File.expand_path(spec_session_path))).to be(true)

      subject.clear_session

      expect(File.exist?('../tmp/.ccli')).to be(false)
    end

    it 'returns if session data is missing' do
      expect(File.exist?('../tmp/.ccli')).to be(false)

      subject.clear_session

      expect(File.exist?('../tmp/.ccli')).to be(false)
    end
  end
end
