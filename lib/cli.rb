# frozen_string_literal: true

require 'rubygems'
require 'commander'
require 'tty-exit'

require_relative './adapters/session_adapter'
require_relative './adapters/cry_adapter'
require_relative './models/account'

class CLI
  include Commander::Methods

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity
  def run
    program :name, 'ccli - cryptopus ccli'
    program :version, '0.1.0'
    program :description, 'CLI tool to manage openshift secrets'

    command :login do |c|
      c.syntax = 'ccli login <url> [options]'
      c.description = 'Logs into the ccli'
      c.option '--token TOKEN', String, 'Authentification Token including api user username'

      c.action do |args, options|
        TTY::Exit.exit_with(:usage_error, 'URL missing') if args.empty?
        SessionAdapter.new.update_session(options.token, args.first)
        puts 'Successfully logged in'
      end
    end

    command :logout do |c|
      c.syntax = 'ccli logout'
      c.description = 'Logs out of the ccli'

      c.action do
        SessionAdapter.new.clear_session
        puts 'Successfully logged out'
      end
    end

    command :account do |c|
      c.syntax = 'ccli account <id> [options]'
      c.description = 'Fetches an account by the given id'
      c.option '--username', String, 'Only show the username of the user'
      c.option '--password', String, 'Only show the password of the user'

      c.action do |args, options|
        TTY::Exit.exit_with(:usage_error, 'ID missing') if args.empty?
        begin
          account = Account.find(args.first)
        rescue SessionMissingError
          TTY::Exit.exit_with(:usage_error, 'Not logged in')
        rescue UnauthorizedError
          TTY::Exit.exit_with(:usage_error, 'Authorization failed')
        rescue SocketError
          TTY::Exit.exit_with(:usage_error, 'Could not connect')
        end
        out = account.username if options.username
        out = account.password if options.password
        puts out || account.to_yaml
      end
    end

    run!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity
end

CLI.new.run if $PROGRAM_NAME == __FILE__
