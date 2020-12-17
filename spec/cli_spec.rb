# frozen_string_literal: true

require 'spec_helper'
require 'commander'
require 'base64'
require 'tty-exit'

require_relative '../lib/cli'

describe CLI do
  subject { described_class.new }
  let(:usage_error_code) { TTY::Exit.exit_code(:usage_error) }
  let(:secret) { OSESecret.new('spec_secret', 'data') }
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
            type: 'credentials'
          }
        }
      }.to_json
      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:get).and_return(json_response)


      expect{ subject.run }
        .to output(/id: 1\naccountname: spec_account\nusername: ccli_account\npassword: gfClNjq21D\ntype: credentials/)
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

  context 'ose-secret-pull' do
    it 'exits successfully when no name given' do
      set_command(:'ose-secret-pull')

      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:save_secret)
      expect(OSESecret).to receive(:all).and_return([secret])

      expect{ subject.run }
        .to output(/Saved secret spec_secret/)
        .to_stdout
    end

    it 'exits successfully when available name given' do
      set_command(:'ose-secret-pull', 'spec_secret')

      cryptopus_adapter = double
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(cryptopus_adapter).to receive(:save_secret)
      expect(OSESecret).to receive(:find_by_name).with('spec_secret')

      expect{ subject.run }
        .to output(/Saved secret spec_secret/)
        .to_stdout
    end

    it 'exits with usage error if multiple arguments are given' do
      set_command(:'ose-secret-pull', 'spec_secret', 'spec_secret2')

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Only a single or no arguments are allowed/)
        .to_stderr
    end

    it 'exits with usage error if no folder is selected' do
      clear_session
      setup_session
      set_command(:'ose-secret-pull')

      expect(OSESecret).to receive(:all).and_return([secret])

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Folder must be selected using cry folder <id>/)
        .to_stderr
    end

    it 'exits with usage error if oc is not installed' do
      set_command(:'ose-secret-pull')

      ose_adapter = OSEAdapter.new
      cmd = double
      negative_result = double
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(ose_adapter).to receive(:cmd).and_return(cmd)
      expect(cmd).to receive(:run!).with('which oc').and_return(negative_result)
      expect(negative_result).to receive(:success?).and_return(false)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/oc is not installed/)
        .to_stderr
    end

    it 'exits with usage error if oc is not logged in' do
      set_command(:'ose-secret-pull')

      ose_adapter = OSEAdapter.new
      cmd = double
      positive_result = double
      negative_result = double
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(ose_adapter).to receive(:cmd).and_return(cmd).exactly(2).times
      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc get secret').and_return(negative_result)
      expect(positive_result).to receive(:success?).and_return(true)
      expect(negative_result).to receive(:success?).and_return(false)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/oc is not logged in/)
        .to_stderr
    end

    it 'exits with usage error if oc secret was not found' do
      set_command(:'ose-secret-pull', 'spec_secret')

      ose_adapter = OSEAdapter.new
      cmd = double
      positive_result = double
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(ose_adapter).to receive(:cmd).and_return(cmd).exactly(3).times
      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc get secret').and_return(positive_result)
      expect(positive_result).to receive(:success?).and_return(true).exactly(2).times
      expect(cmd).to receive(:run).with("oc get -o yaml secret --field-selector='metadata.name=spec_secret' " \
                                        "-l cryptopus-sync=true").and_raise(exit_error('oc get secret'))

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Secret with the given name spec_secret was not found/)
        .to_stderr
    end

    it 'exits with usage error if not authorized' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-pull')

      response = double
      expect(OSESecret).to receive(:all).and_return([secret])
      expect(Net::HTTP).to receive(:start).with('cryptopus.example.com', 443, use_ssl: true).and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Authorization failed/)
        .to_stderr
    end

    it 'exits with usage error if connection failed' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-pull')

      expect(OSESecret).to receive(:all).and_return([secret])
      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Could not connect/)
        .to_stderr
    end
  end

  context 'ose-secret-push' do
    it 'exits successfully if name is given' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push', 'spec_secret')

      cryptopus_adapter = double
      ose_adapter = double
      account = Account.new(accountname: 'spec_secret', id: 1)
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(account).to receive(:to_osesecret).and_return(secret)
      expect(cryptopus_adapter).to receive(:find_account_by_name).with('spec_secret').and_return(account)
      expect(Account).to receive(:find).with(1).and_return(account)
      expect(ose_adapter).to receive(:insert_secret)
      expect { subject.run }
        .to output(/Secret spec_secret was successfully applied/)
        .to_stdout
    end

    it 'exits successfully if name is missing' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push')

      ose_adapter = double
      accounts = [Account.new(accountname: 'secret1', ose_secret: { 'metadata' => { 'name' => 'secret1' } }.to_yaml, id: 1),
                  Account.new(accountname: 'secret2', ose_secret: { 'metadata' => { 'name' => 'secret2' } }.to_yaml, id: 2)]
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)

      expect(Folder).to receive(:find).with(1).and_return(Folder.new(id: 1, accounts: accounts))

      expect(Account).to receive(:find).with(1).exactly(:once).and_return(accounts[0])
      expect(Account).to receive(:find).with(2).exactly(:once).and_return(accounts[1])
      expect(ose_adapter).to receive(:insert_secret).exactly(:twice)

      expect { subject.run }
        .to output(/Secret secret2 was successfully applied/)
        .to_stdout
    end

    it 'exits with usage error if multiple arguments' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push', 'spec_secret1', 'spec_secret2')

      cryptopus_adapter = double
      ose_adapter = double
      account = Account.new(id: 1)
      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(account).to receive(:to_osesecret).and_return(secret)
      expect(cryptopus_adapter).to receive(:find_account_by_name).and_return(account)
      expect(ose_adapter).to receive(:insert_secret)
      expect(Account).to receive(:find).and_return(account)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect { subject.run }.to output(/Only one secret can be pushed/).to_stderr
    end

    it 'exits with usage error if no folder is selected' do
      clear_session
      setup_session
      set_command(:'ose-secret-push', 'spec_secret')

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect { subject.run }.to output(/Folder must be selected using cry folder <id>/).to_stderr
    end

    it 'exits with usage error if not authorized' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push', 'spec_secret')

      response = double
      expect(Net::HTTP).to receive(:start).with('cryptopus.example.com', 443, use_ssl: true).and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPUnauthorized).and_return(true)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Authorization failed/)
        .to_stderr
    end

    it 'exits with usage error if connection fails' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push', 'spec_secret')

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect { subject.run }.to output(/Could not connect/).to_stderr
    end

    it 'exits with usage error if oc is not installed' do
      setup_session
      set_command(:'ose-secret-push', 'spec_secret')

      cryptopus_adapter = double
      ose_adapter = OSEAdapter.new
      account = Account.new(id: 1)
      cmd = double
      negative_result = double

      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(account).to receive(:to_osesecret).and_return(secret)
      expect(cryptopus_adapter).to receive(:find_account_by_name).and_return(account)
      expect(ose_adapter).to receive(:cmd).and_return(cmd)
      expect(cmd).to receive(:run!).with('which oc').and_return(negative_result)
      expect(negative_result).to receive(:success?).and_return(false)
      expect(Account).to receive(:find).and_return(account)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/oc is not installed/)
        .to_stderr
    end

    it 'exits with usage error if oc is not logged in' do
      set_command(:'ose-secret-push', 'spec_secret')

      cryptopus_adapter = double
      ose_adapter = OSEAdapter.new
      account = Account.new(id: 1)
      cmd = double
      negative_result = double
      positive_result = double

      expect(CryptopusAdapter).to receive(:new).and_return(cryptopus_adapter)
      expect(OSEAdapter).to receive(:new).and_return(ose_adapter)
      expect(account).to receive(:to_osesecret).and_return(secret)
      expect(cryptopus_adapter).to receive(:find_account_by_name).and_return(account)
      expect(ose_adapter).to receive(:cmd).and_return(cmd).exactly(2).times
      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc get secret').and_return(negative_result)
      expect(positive_result).to receive(:success?).and_return(true)
      expect(negative_result).to receive(:success?).and_return(false)
      expect(Account).to receive(:find).and_return(account)

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/oc is not logged in/)
        .to_stderr
    end

    it 'exits with usage error if cryptopus account was not found' do
      setup_session
      select_folder(1)
      set_command(:'ose-secret-push', 'spec_secret')

      expect(Account).to receive(:find_by_name_and_folder_id).with('spec_secret', 1)
      expect(Folder).to receive(:find).and_return(Folder.new(id: 1))

      expect(Kernel).to receive(:exit).with(usage_error_code)
      expect{ subject.run }
        .to output(/Secret with the given name spec_secret was not found/)
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
