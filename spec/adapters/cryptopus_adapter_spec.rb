# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'psych'

describe CryptopusAdapter do
  subject { described_class.new }
  let (:spec_session_path) { 'spec/tmp/.ccli/session' }
  let (:session_adapter) { SessionAdapter.new }

  before(:each) do
    stub_const("SessionAdapter::FILE_LOCATION", spec_session_path)
  end

  context 'get' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'returns encryptable hash from http response' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com'})

      response = double
      json_response = {
        data: {
          id: 1,
          attributes: {
            name: 'spec_encryptable',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_encryptable',
            cleartext_pin: '1234',
            cleartext_token: 'xcFT',
            cleartext_email: 'test@test.com',
            cleartext_custom_attr: 'wow',
            type: 'credentials'
          }
        }
      }.to_json
      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(response).to receive(:body).and_return(json_response)

      encryptable = JSON.parse(subject.get('encryptables/3'), symbolize_names: true)

      data = encryptable[:data]
      attrs = data[:attributes]
      expect(data[:id]).to eq(1)
      expect(attrs[:name]).to eq('spec_encryptable')
      expect(attrs[:cleartext_username]).to eq('ccli_encryptable')
      expect(attrs[:cleartext_password]).to eq('gfClNjq21D')
      expect(attrs[:cleartext_pin]).to eq('1234')
      expect(attrs[:cleartext_token]).to eq('xcFT')
      expect(attrs[:cleartext_email]).to eq('test@test.com')
      expect(attrs[:cleartext_custom_attr]).to eq('wow')
      expect(attrs[:type]).to eq('credentials')
    end
    
    it 'raises error if unauthorized' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect do
        subject.get('encryptables/3')
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if forbidden' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(true)

      expect do
        subject.get('encryptables/3')
      end.to raise_error(ForbiddenError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      expect do
        subject.get('encryptables/3')
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.get('encryptables/3')
      end.to raise_error(SessionMissingError)
    end
  end

  context 'post' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'sends request using given body' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com'})

      json_body = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_account',
            cleartext_pin: '1234',
            cleartext_token: 'xcFT',
            cleartext_email: 'test@test.com',
            cleartext_custom_attr: 'wow',
            type: 'credentials'
          }
        }
      }.to_json
      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(subject).to receive(:send_request)
                     .with(having_attributes(body: json_body), kind_of(URI))
                     .and_call_original
      expect(response).to receive(:body).and_return({}.to_json)

      subject.post('encryptables', json_body)
    end
    
    it 'raises error if unauthorized' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect do
        subject.post('encryptables', { attrs: 'name' })
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if forbidden' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(true)

      expect do
        subject.post('encryptables', { attrs: 'name' })
      end.to raise_error(ForbiddenError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      expect do
        subject.post('encryptables', { attrs: 'name' })
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.post('encryptables', { attrs: 'name' })
      end.to raise_error(SessionMissingError)
    end
  end

  context 'patch' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'sends request using given body' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com'})

      json_body = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_account',
            cleartext_pin: '1234',
            cleartext_token: 'xcFT',
            cleartext_email: 'test@test.com',
            cleartext_custom_attr: 'wow',
            type: 'credentials'
          }
        }
      }.to_json
      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(subject).to receive(:send_request)
                     .with(having_attributes(body: json_body), kind_of(URI))
                     .and_call_original
      expect(response).to receive(:body).and_return({}.to_json)

      subject.patch('encryptables', json_body)
    end
    
    it 'raises error if unauthorized' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect do
        subject.patch('encryptables', { attrs: 'name' })
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if forbidden' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(true)

      expect do
        subject.patch('encryptables', { attrs: 'name' })
      end.to raise_error(ForbiddenError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.example.com' })

      expect do
        subject.patch('encryptables', { attrs: 'name' })
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.patch('encryptables', { attrs: 'name' })
      end.to raise_error(SessionMissingError)
    end
  end
end
