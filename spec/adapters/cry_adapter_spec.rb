# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'psych'

describe CryAdapter do
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

    it 'returns account hash from http response' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com'})

      response = double
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_account',
            category: 'regular'
          }
        }
      }.to_json
      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.specs.com', 443)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)

      expect(response).to receive(:body).and_return(json_response)

      account = subject.get('accounts', 3)

      data = account['data']
      attrs = data['attributes']
      expect(data['id']).to eq(1)
      expect(attrs['accountname']).to eq('spec_account')
      expect(attrs['cleartext_username']).to eq('ccli_account')
      expect(attrs['cleartext_password']).to eq('gfClNjq21D')
      expect(attrs['category']).to eq('regular')
    end
    
    it 'raises error if unauthorized' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.specs.com', 443)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect do
        subject.get('accounts', 3)
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      expect do
        subject.get('accounts', 3)
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.get('accounts', 3)
      end.to raise_error(SessionMissingError)
    end
  end
end
