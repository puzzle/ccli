# frozen_string_literal: true

require 'rubygems'
require 'commander'
require 'tty-exit'

require_relative './adapters/session_adapter.rb'

class CLI
  include Commander::Methods

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def run
    program :name, 'ccli - cryptopus ccli'
    program :version, '0.1.0'
    program :description, 'CLI tool to manage openshift secrets'

    command :login do |c|
      c.syntax = 'ccli login <url> [options]'
      c.description = 'Logs into the ccli'
      c.option '--token TOKEN', String, 'Authentification Token including api user username'

      c.action do |args, options|
        TTY::Exit.exit_with(:usage_error, :default) if args.empty?
        SessionAdapter.instance.update_session(options.token, args.first)
        puts 'Successfully logged in'
      end
    end

    command :logout do |c|
      c.syntax = 'ccli logout'
      c.description = 'Logs out of the ccli'

      c.action do
        SessionAdapter.instance.clear_session
        puts 'Successfully logged out'
      end
    end

    run!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end

CLI.new.run if $PROGRAM_NAME == __FILE__
