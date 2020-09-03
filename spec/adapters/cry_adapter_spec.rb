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
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(response).to receive(:body).and_return(json_response)

      account = subject.get('accounts/3')

      data = account[:data]
      attrs = data[:attributes]
      expect(data[:id]).to eq(1)
      expect(attrs[:accountname]).to eq('spec_account')
      expect(attrs[:cleartext_username]).to eq('ccli_account')
      expect(attrs[:cleartext_password]).to eq('gfClNjq21D')
      expect(attrs[:category]).to eq('regular')
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
        subject.get('accounts/3')
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      expect do
        subject.get('accounts/3')
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.get('accounts/3')
      end.to raise_error(SessionMissingError)
    end
  end

  context 'post' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'sends request using given body' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com'})

      json_body = {
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
      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.specs.com', 443)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(subject).to receive(:send_request)
                     .with(having_attributes(body: json_body), kind_of(URI))
                     .and_call_original
      expect(response).to receive(:body).and_return({}.to_json)

      subject.post('accounts', json_body)
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
        subject.post('accounts', { attrs: 'name' })
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      expect do
        subject.post('accounts', { attrs: 'name' })
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.post('accounts', { attrs: 'name' })
      end.to raise_error(SessionMissingError)
    end
  end

  context 'patch' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'sends request using given body' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com'})

      json_body = {
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
      response = double

      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.specs.com', 443)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(false)
      expect(response).to receive(:is_a?).with(Net::HTTPForbidden).and_return(false)

      expect(subject).to receive(:send_request)
                     .with(having_attributes(body: json_body), kind_of(URI))
                     .and_call_original
      expect(response).to receive(:body).and_return({}.to_json)

      subject.patch('accounts', json_body)
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
        subject.patch('accounts', { attrs: 'name' })
      end.to raise_error(UnauthorizedError)
    end
    
    it 'raises error if connection fails' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      expect do
        subject.patch('accounts', { attrs: 'name' })
      end.to raise_error(SocketError)
    end
    
    it 'raises error if session is missing' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      expect do
        subject.patch('accounts', { attrs: 'name' })
      end.to raise_error(SessionMissingError)
    end
  end

  context 'save_secrets' do
    after(:each) do
      FileUtils.rm_r(File.expand_path('spec/tmp')) if File.exist?('../tmp/.ccli')
    end

    it 'sends post request if secret not persisted yet' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com', folder: '1' })

      secrets = [OSESecret.new('spec_secret', {})]
      expect(subject).to receive(:folder_accounts).exactly(:once).and_return([])
      secret_account = secrets.first.to_account
      secret_account.folder = '1'
      expect(subject).to receive(:post)
                     .with('accounts', secret_account.to_json)
                     .exactly(:once)
                     .and_return([])

      subject.save_secrets(secrets)
    end

    it 'sends patch request if secret already persisted' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com', folder: '1' })

      secrets = [OSESecret.new('spec_secret', {})]
      expect(subject).to receive(:folder_accounts).exactly(:once).and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret', id: '1')])
      secret_account = secrets.first.to_account
      secret_account.folder = '1'
      expect(subject).to receive(:patch)
                     .with('accounts/1', secret_account.to_json)
                     .exactly(:once)

      subject.save_secrets(secrets)
    end

    it 'sends both patch and post requests for each secret respectively' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com', folder: '1' })

      secrets = [OSESecret.new('spec_secret', {}), OSESecret.new('spec_secret2', {})]
      expect(subject).to receive(:folder_accounts).exactly(:twice).and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret', id: '1')])
      secret_account1 = secrets[0].to_account
      secret_account1.folder = '1'
      secret_account2 = secrets[1].to_account
      secret_account2.folder = '1'
      expect(subject).to receive(:patch)
                     .with('accounts/1', secret_account1.to_json)
                     .exactly(:once)
                     .and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret')])
      expect(subject).to receive(:post)
                     .with('accounts', secret_account2.to_json)
                     .exactly(:once)
                     .and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret')])

      subject.save_secrets(secrets)
    end

    it 'raises error if no session is present' do
      FileUtils.rm_r(File.expand_path('spec/tmp'))

      secrets = [OSESecret.new('spec_secret', {})]

      expect do
        subject.save_secrets(secrets)
      end.to raise_error(SessionMissingError)
    end

    it 'raises error if folder not selected' do
      encoded_token = Base64.encode64('bob;1234')

      session_adapter.update_session({ encoded_token: encoded_token, url: 'https://cryptopus.specs.com' })

      secrets = [OSESecret.new('spec_secret', {})]

      expect do
        subject.save_secrets(secrets)
      end.to raise_error(NoFolderSelectedError)
    end
  end

  context 'find_secret_account_by_name' do
    it 'gets show for secret account' do
      expect(subject).to receive(:folder_accounts).and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret', id: '1')])

      expect(subject).to receive(:get).with('accounts/1').exactly(:once)

      subject.find_secret_account_by_name('spec_secret')
    end

    it 'raises error if account was not found' do
      expect(subject).to receive(:folder_accounts).and_return([Account.new('spec_secret', 'spec_secret', 'pass', 'openshift_secret', id: '1')])

      expect do
        subject.find_secret_account_by_name('unavailable_secret')
      end.to raise_error(CryptopusAccountNotFoundError)
    end
  end
end
