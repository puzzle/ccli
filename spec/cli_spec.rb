# frozen_string_literal: true

require 'spec_helper'
require 'commander'
require 'base64'
require 'tty-exit'

require_relative '../lib/cli'

describe CLI do
  subject { described_class.new }

  before(:each) do
    Commander::Runner.instance_variable_set :'@singleton', nil
  end

  context 'login' do
    it 'exits with usage error if url missing' do
      stub_const('ARGV', ['login'])

      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error))
      expect{ subject.run }
        .to output(/URL missing/)
        .to_stderr
    end

    it 'exits successfully when url given' do
      stub_const('ARGV', ['login', 'https://cryptopus.specs.com'])
      stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session' )

      expect{ subject.run }
        .to output(/Successfully logged in/)
        .to_stdout
    end
  end

  context 'logout' do
    it 'exits successfully when session data present' do
      setup_session

      stub_const('ARGV', ['logout'])

      expect{ subject.run }
        .to output(/Successfully logged out/)
        .to_stdout
    end

    it 'exits successfully when no session data present' do
      stub_const('ARGV', ['logout'])

      expect{ subject.run }
        .to output(/Successfully logged out/)
        .to_stdout
    end
  end

  context 'account' do
    it 'exits successfully and showing the whole account when no flag is set' do
      setup_session

      stub_const('ARGV', ['account', '1'])
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
      }
      cry_adapter = double
      expect(CryAdapter).to receive(:new).and_return(cry_adapter)
      expect(cry_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/id: 1\naccountname: spec_account\nusername: ccli_account\npassword: gfClNjq21D\ncategory: regular/)
        .to_stdout
    end

    it 'exits successfully and showing only username with flag' do
      setup_session

      stub_const('ARGV', ['account', '1', '--username'])
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
      }
      cry_adapter = double
      expect(CryAdapter).to receive(:new).and_return(cry_adapter)
      expect(cry_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/ccli_account/)
        .to_stdout
    end

    it 'exits successfully and showing only password with flag' do
      setup_session

      stub_const('ARGV', ['account', '1', '--password'])
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
      }
      cry_adapter = double
      expect(CryAdapter).to receive(:new).and_return(cry_adapter)
      expect(cry_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/gfClNjq21D/)
        .to_stdout
    end

    it 'exits with usage error if session missing' do
      stub_const('ARGV', ['account', '1'])

      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error))
      expect{ subject.run }
        .to output(/Not logged in/)
        .to_stderr
    end

    it 'exits with usage error if authorization fails' do
      setup_session

      stub_const('ARGV', ['account', '1'])
      response = double
      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.specs.com', 443)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error))
      expect{ subject.run }
        .to output(/Authorization failed/)
        .to_stderr
    end

    it 'exits with usage error connection fails' do
      setup_session

      stub_const('ARGV', ['account', '1'])

      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error))
      expect{ subject.run }
        .to output(/Could not connect/)
        .to_stderr
    end
  end

  context 'folder' do
    it 'exits successfully when id given' do
      stub_const('ARGV', ['folder', '1'])

      expect{ subject.run }
        .to output(/Selected Folder with id: 1/)
        .to_stdout
    end

    it 'exits with usage error if id missing' do
      stub_const('ARGV', ['folder'])

      # Since we have to mock the Kernel.exit call to prevent the whole test suite from exiting
      # the code after the TTY::Exit.exit_with call will just continue to run, which would not happen
      # in production usage. Thus, we have to mock these other methods as well to prevent an error from raising.
      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error)).exactly(2).times
      allow_any_instance_of(NilClass).to receive(:match?).and_return(false)
      session_adapter = double
      expect(SessionAdapter).to receive(:new).and_return(session_adapter)
      expect(session_adapter).to receive(:update_session)


      expect{ subject.run }
        .to output(/id missing/)
        .to_stderr
    end

    it 'exits with usage error if id not a integer' do
      stub_const('ARGV', ['folder', 'a'])

      expect(Kernel).to receive(:exit).with(TTY::Exit.exit_code(:usage_error))
      expect{ subject.run }
        .to output(/id invalid/)
        .to_stderr
    end
  end

  context 'ose secret pull' do
    it 'exits successfully when no name given' do
      stub_const('ARGV', ['ose secret pull'])

      cry_adapter = double
      expect(CryAdapter).to receive(:new).and_return(cry_adapter)
      expect(cry_adapter).to receive(:save_secrets)
      expect(OSESecret).to receive(:all)

      expect{ subject.run }
        .to output(/Saved secrets of current project/)
        .to_stdout
    end
  end

  private

  def setup_session
    encoded_token = Base64.encode64('bob;1234')
    stub_const('ARGV', ['login', 'https://cryptopus.specs.com', "--token=#{encoded_token}"])
    stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session')

    subject.run

    Commander::Runner.instance_variable_set :'@singleton', nil
  end
end
