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

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
  def run
    program :name, 'ccli - cryptopus ccli'
    program :version, '1.0.0'
    program :description, 'CLI tool to manage Openshift Secrets via Cryptopus'
    program :help, 'Source Code', 'https://www.github.com/puzzle/ccli'
    program :help, 'Usage', 'ccli [flags]'

    command :login do |c|
      c.syntax = 'ccli login <url> [options]'
      c.description = 'Logs in to the ccli'
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
      c.description = 'Selects the Cryptopus folder by id'

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
      c.summary = 'Pulls secret from Openshift to Cryptopus'
      c.description = "Pulls the Secret from Openshift and pushes them to Cryptopus.\n" \
                      'If a Cryptopus Account in the selected folder using the name ' \
                      "of the given secret is already present, it will be updated accordingly.\n" \
                      'If no name is given, it will pull all secrets inside the selected project.'

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

    command :'ose secret push' do |c|
      c.syntax = 'ccli ose secret push <secret-name>'
      c.summary = 'Pushes secret from Cryptopus to Openshift'
      c.description = 'Pushes the Secret to Openshift by retrieving it from Cryptopus first. ' \
                      'If a Secret in the selected Openshift project using the name ' \
                      'of the given accountname is already present, it will be updated accordingly.'

      c.action do |args|
        secret_name = args.first
        TTY::Exit.exit_with(:usage_error, 'Secret name is missing') unless secret_name
        TTY::Exit.exit_with(:usage_error, 'Only one secret can be pushed') if args.length > 1
        begin
          secret = CryAdapter.new.find_secret_account_by_name(secret_name)
          OSEAdapter.new.insert_secret(Account.from_json(secret).to_osesecret)
          puts 'Secret was successfully applied'
        rescue NoFolderSelectedError
          TTY::Exit.exit_with(:usage_error, 'Folder must be selected using ccli folder <id>')
        rescue OpenshiftClientMissingError
          TTY::Exit.exit_with(:usage_error, 'oc is not installed')
        rescue OpenshiftClientNotLoggedInError
          TTY::Exit.exit_with(:usage_error, 'oc is not logged in')
        rescue CryptopusAccountNotFoundError
          TTY::Exit.exit_with(:usage_error, 'secret with the given name ' \
                              "#{args.first} was not found")
        end
      end
    end

    run!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
end

CLI.new.run if $PROGRAM_NAME == __FILE__
