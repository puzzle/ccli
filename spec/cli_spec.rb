# frozen_string_literal: true

require 'spec_helper'
require 'commander'
require 'base64'
require 'tty-exit'

require_relative '../lib/cli'

describe CLI do
  subject { described_class.new }
  let(:usage_error_code) { TTY::Exit.exit_code(:usage_error) }
  let(:session_adapter) { SessionAdapter.new }

  before(:each) do
    Commander::Runner.instance_variable_set :'@singleton', nil
  end

  after(:each) do
    clear_session
  end

  context 'login' do
    before(:each) do
      stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session' )
      allow(Team).to receive(:all)
    end

    it 'exits with usage error if args missing' do
      set_command(:login)

      session_adapter = SessionAdapter.new
      cryptopus_adapter = double
      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect(SessionAdapter).to receive(:new).at_least(:once).and_return(session_adapter)
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      allow_any_instance_of(NilClass).to receive(:split).and_return(["a", "b"])
      expect(cryptopus_adapter).to receive(:renewed_auth_token)
      allow(session_adapter).to receive(:update_session)
      allow(session_adapter).to receive(:update_session)
      expect{ subject.run }
        .to output(/Credentials missing/)
        .to_stderr
    end

    it 'exits with usage error if url missing' do
      set_command(:login, 'WEj2eCJnwKbjw@')

      session_adapter = SessionAdapter.new
      cryptopus_adapter = double
      expect(SessionAdapter).to receive(:new).at_least(:once).and_return(session_adapter)
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:renewed_auth_token)
      allow(session_adapter).to receive(:update_session)
      allow(session_adapter).to receive(:update_session)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/URL missing/)
        .to_stderr
    end

    it 'exits with usage error if token missing' do
      set_command(:login, '@https://cryptopus.example.com')

      expect(Kernel).to receive(:exit).with(usage_error_code).exactly(2).times
      expect{ subject.run }
        .to output(/Token missing/)
        .to_stderr
    end

    it 'exits with usage error if authentification test returns 401' do
      set_command(:login, 'WEj2eCJnwKbjw@https://cryptopus.example.com')


      expect(subject).to receive(:renew_auth_token)
      expect(Team).to receive(:all).and_raise(UnauthorizedError)
      expect(Kernel).to receive(:exit).with(usage_error_code).exactly(:once)
      expect{ subject.run }
        .to output(/Authorization failed/)
        .to_stderr
    end

    it 'exits successfully when url and token given' do
      set_command(:login, 'WEj2eCJnwKbjw@https://cryptopus.example.com')

      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:renewed_auth_token)

      expect{ subject.run }
        .to output(/Successfully logged in/)
        .to_stdout
    end
  end

  context 'logout' do
    it 'exits successfully when session data present' do
      setup_session

      set_command(:logout)

      expect{ subject.run }
        .to output(/Successfully logged out/)
        .to_stdout
    end

    it 'exits successfully when no session data present' do
      set_command(:logout)

      expect{ subject.run }
        .to output(/Successfully logged out/)
        .to_stdout
    end
  end

  context 'account' do
    it 'exits successfully and showing the whole account when no flag is set' do
      setup_session

      set_command(:account, '1')
      json_response = {
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
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)


      expect{ subject.run }
        .to output(/id: 1\naccountname: spec_account\nusername: ccli_account\npassword: gfClNjq21D\npin: 1234\ntoken: xcFT\nemail: test@test.com\ncustom_attribute: wow\ntype: credentials/)
        .to_stdout
    end

    it 'exits successfully and showing only username with flag' do
      setup_session

      set_command(:account, '1', '--username')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_account',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/ccli_account/)
        .to_stdout
    end

    it 'exits successfully and showing only password with flag' do
      setup_session

      set_command(:account, '1', '--password')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_password: 'gfClNjq21D',
            cleartext_username: 'ccli_account',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/gfClNjq21D/)
        .to_stdout
    end

    it 'exits successfully and showing only pin with flag' do
      setup_session

      set_command(:account, '1', '--pin')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_pin: '3819',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/3819/)
              .to_stdout
    end

    it 'exits successfully and showing only token with flag' do
      setup_session

      set_command(:account, '1', '--token')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_token: 'fdSDALwalS',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/fdSDALwalS/)
              .to_stdout
    end

    it 'exits successfully and showing only email with flag' do
      setup_session

      set_command(:account, '1', '--email')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_email: 'hallo@welcome.com',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/hallo@welcome.com/)
              .to_stdout
    end

    it 'exits successfully and showing only custom attribute with flag' do
      setup_session

      set_command(:account, '1', '--customAttribute')
      json_response = {
        data: {
          id: 1,
          attributes: {
            accountname: 'spec_account',
            cleartext_custom_attribute: 'this is my secret attribute hehehe',
            type: 'Account::Credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)

      expect{ subject.run }
        .to output(/this is my secret attribute hehehe/)
              .to_stdout
    end

    it 'exits with usage error if session missing' do
      set_command(:account, '1')

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Not logged in/)
        .to_stderr
    end

    it 'exits with usage error if authorization fails' do
      setup_session

      set_command(:account, '1')
      response = double
      expect(Net::HTTP).to receive(:start)
                       .with('cryptopus.example.com', 443, use_ssl: true)
                       .and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Authorization failed/)
        .to_stderr
    end

    it 'exits with usage error connection fails' do
      setup_session

      set_command(:account, '1')

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Could not connect/)
        .to_stderr
    end
  end

  context 'folder' do
    it 'exits successfully when id given' do
      set_command(:folder, '1')

      expect{ subject.run }
        .to output(/Selected Folder with id: 1/)
        .to_stdout
    end

    it 'exits with usage error if id missing' do
      set_command(:folder)

      # Since we have to mock the Kernel.exit call to prevent the whole test suite from exiting
      # the code after the TTY::Exit.exit_with call will just continue to run, which would not happen
      # in production usage. Thus, we have to mock these other methods as well to prevent an error from raising.
      expect(Kernel).to receive(:exit).with(usage_error_code).exactly(2).times
      allow_any_instance_of(NilClass).to receive(:match?).and_return(false)
      expect(SessionAdapter).to receive(:new).and_return(session_adapter).at_least(:once)
      expect(session_adapter).to receive(:update_session)


      expect{ subject.run }
        .to output(/id missing/)
        .to_stderr
    end

    it 'exits with usage error if id not a integer' do
      set_command(:folder, 'a')

      expect(SessionAdapter).to receive(:new).and_return(session_adapter).at_least(:once)
      expect(session_adapter).to receive(:update_session)
      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/id invalid/)
        .to_stderr
    end
  end

  context 'use' do
    it 'selects correct folder by team and folder name' do
      set_command(:use, 'bbt/ruby')

      session_adapter = SessionAdapter.new
      teams = [Team.new(name: 'bbt', folders: [Folder.new(name: 'ruby', id: 1), Folder.new(name: 'java', id: 2)], id: 3)]
      expect(Team).to receive(:all).and_return(teams)
      expect(SessionAdapter).to receive(:new).exactly(2).times.and_return(session_adapter)
      expect(session_adapter).to receive(:update_session).with({ folder: 1 })

      expect { subject.run }
        .to output(/Selected folder ruby/)
        .to_stdout
    end

    it 'selects correct folder by team and folder name not considering spaces and cases' do
      set_command(:use, 'pUzZle-Bbt/jAva-lAng')

      session_adapter = SessionAdapter.new
      teams = [Team.new(name: 'PuzzlE bBt', folders: [Folder.new(name: 'ruBY laNg', id: 1), Folder.new(name: 'JAva lanG', id: 2)], id: 3)]
      expect(Team).to receive(:all).and_return(teams)
      expect(SessionAdapter).to receive(:new).exactly(2).times.and_return(session_adapter)
      expect(session_adapter).to receive(:update_session).with({ folder: 2 })

      expect { subject.run }
        .to output(/Selected folder java-lang/)
        .to_stdout
    end

    it 'exits with usage error if argument is missing' do
      set_command(:use)

      team = double
      folder = double
      allow_any_instance_of(NilClass).to receive(:split).and_return(['a', 'b'])


      expect(Team).to receive(:find_by_name).and_return(team)
      expect(team).to receive(:folder_by_name).and_return(folder)
      expect(folder).to receive(:id).and_return(1)

      expect(Kernel).to receive(:exit).with(usage_error_code)

      expect { subject.run }
        .to output(/Arguments missing\nUsage: cry use <team\/folder>/)
        .to_stderr
    end

    it 'exits with usage error if team name is missing' do
      set_command(:use, '/ruby')

      team = double
      folder = double

      expect(Team).to receive(:find_by_name).and_return(team)
      expect(team).to receive(:folder_by_name).and_return(folder)
      expect(folder).to receive(:id).and_return(1)

      expect(Kernel).to receive(:exit).with(usage_error_code)

      expect { subject.run }
        .to output(/Team name is missing\nUsage: cry use <team\/folder>/)
        .to_stderr
    end

    it 'exits with usage error if folder name is missing' do
      set_command(:use, 'puzzle-bbt/')

      team = double
      folder = double
      allow_any_instance_of(NilClass).to receive(:downcase)

      expect(Team).to receive(:find_by_name).and_return(team)
      expect(team).to receive(:folder_by_name).and_return(folder)
      expect(folder).to receive(:id).and_return(1)

      expect(Kernel).to receive(:exit).with(usage_error_code)

      expect { subject.run }
        .to output(/Folder name is missing\nUsage: cry use <team\/folder>/)
        .to_stderr
    end

    it 'exits with usage error if team was not found' do
      set_command(:use, 'puzzle-java/ruby')

      expect(Team).to receive(:all).and_return([Team.new(name: 'puzzle-bbt'), Team.new(name: 'puzzle-ruby')])

      expect(Kernel).to receive(:exit).with(usage_error_code)

      expect { subject.run }
        .to output(/Team with the given name puzzle-java was not found/)
        .to_stderr
    end

    it 'exits with usage error if folder was not found' do
      set_command(:use, 'puzzle-bbt/java')

      expect(Team).to receive(:all).and_return([Team.new(name: 'puzzle-bbt',
                                                         folders: [Folder.new(name: 'ruby')]),
                                                Team.new(name: 'puzzle-ruby')])

      expect(Kernel).to receive(:exit).with(usage_error_code)

      expect { subject.run }
        .to output(/Folder with the given name java was not found/)
        .to_stderr
    end
  end

  private

  def setup_session
    stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session')

    session_adapter.update_session( { token:  '1234', username: 'bob', url: 'https://cryptopus.example.com' } )
  end

  def select_folder(id)
    stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session')

    session_adapter.update_session({ folder:  id })
  end

  def clear_session
    stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session')

    session_adapter.clear_session
  end

  def set_command(command, *args)
    stub_const('ARGV', [command.to_s] + args)
  end
end
