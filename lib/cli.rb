# frozen_string_literal: true

require 'rubygems'
require 'commander'
require 'tty-exit'

require_relative './adapters/session_adapter'
require_relative './adapters/cry_adapter'
require_relative './adapters/ose_adapter'
require_relative './models/account'
require_relative './models/ose_secret'

class CLI
  include Commander::Methods

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity
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
        SessionAdapter.new.update_session({ encoded_token: options.token, url: args.first })
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
        TTY::Exit.exit_with(:usage_error, 'id missing') if args.empty?
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

    command :folder do |c|
      c.syntax = 'ccli folder <id>'
      c.description = 'Selects the current cryptopus folder'

      c.action do |args|
        id = args.first
        TTY::Exit.exit_with(:usage_error, 'id missing') unless id
        TTY::Exit.exit_with(:usage_error, 'id invalid') unless id.match?(/(^\d{1,10}$)/)
        SessionAdapter.new.update_session({ folder: id })

        puts "Selected Folder with id: #{id}"
      end
    end

    command :'ose secret pull' do |c|
      c.syntax = 'ccli ose secret pull <secret-name>'
      c.description = 'Selects the current cryptopus folder'

      c.action do |args|
        begin
          if args.empty?
            CryAdapter.new.save_secrets(OSESecret.all)
            puts 'Saved secrets of current project'
          elsif args.length == 1
            CryAdapter.new.save_secrets([OSESecret.find_by_name(args.first)])
            puts "Saved secret #{args.first}"
          else
            TTY::Exit.exit_with(:usage_error, 'Only a single or no argument are allowed')
          end
        rescue NoFolderSelectedError
          TTY::Exit.exit_with(:usage_error, 'Folder must be selected using ccli folder <id>')
        rescue OpenshiftClientMissingError
          TTY::Exit.exit_with(:usage_error, 'oc is not installed')
        rescue OpenshiftClientNotLoggedInError
          TTY::Exit.exit_with(:usage_error, 'oc is not logged in')
        rescue OpenshiftSecretNotFoundError
          TTY::Exit.exit_with(:usage_error, 'secret with the given name ' \
                              "#{args.first} was not found")
        end
      end
    end

    run!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity
end

CLI.new.run if $PROGRAM_NAME == __FILE__
