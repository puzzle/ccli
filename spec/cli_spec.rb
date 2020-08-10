# frozen_string_literal: true

require 'spec_helper'
require 'commander'

require_relative '../lib/cli'

describe CLI do
  context 'login' do
    it 'exits with usage error if url missing' do
      expect{system('ruby ./lib/cli.rb login')}
        .to output(/usage error/)
        .to_stderr_from_any_process
    end

    it 'exits successfully when url given' do
      stub_const("SessionAdapter::FILE_LOCATION", 'spec/tmp/.ccli/session' )

      expect{ system('ruby ./lib/cli.rb login https://cryptopus.specs.ch') }
        .to output(/Successfully logged in/)
        .to_stdout_from_any_process
    end
  end

  context 'logout' do
    it 'exits successfully when session data present' do
      system('ruby ./lib/cli.rb login https://cryptopus.specs.ch')

      expect{ system('ruby ./lib/cli.rb logout') }
        .to output(/Successfully logged out/)
        .to_stdout_from_any_process
    end

    it 'exits successfully when no session data present' do
      expect{ system('ruby ./lib/cli.rb logout') }
        .to output(/Successfully logged out/)
        .to_stdout_from_any_process
    end
  end
end
