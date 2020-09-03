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
        execute_action do
          session_adapter.update_session({ encoded_token: options.token, url: args.first })
          puts 'Successfully logged in'
        end
      end
    end

    command :logout do |c|
      c.syntax = 'ccli logout'
      c.description = 'Logs out of the ccli'

      c.action do
        execute_action do
          session_adapter.clear_session
          puts 'Successfully logged out'
        end
      end
    end

    command :account do |c|
      c.syntax = 'ccli account <id> [options]'
      c.description = 'Fetches an account by the given id'
      c.option '--username', String, 'Only show the username of the user'
      c.option '--password', String, 'Only show the password of the user'

      c.action do |args, options|
        TTY::Exit.exit_with(:usage_error, 'id missing') if args.empty?
        execute_action do
          account = Account.find(args.first)
          out = account.username if options.username
          out = account.password if options.password
          puts out || account.to_yaml
        end
      end
    end

    command :folder do |c|
      c.syntax = 'ccli folder <id>'
      c.description = 'Selects the Cryptopus folder by id'

      c.action do |args|
        id = args.first
        TTY::Exit.exit_with(:usage_error, 'id missing') unless id
        TTY::Exit.exit_with(:usage_error, 'id invalid') unless id.match?(/(^\d{1,10}$)/)

        execute_action do
          session_adapter.update_session({ folder: id })

          puts "Selected Folder with id: #{id}"
        end
      end
    end

    command :'ose-secret-pull' do |c|
      c.syntax = 'ccli ose secret pull <secret-name>'
      c.summary = 'Pulls secret from Openshift to Cryptopus'
      c.description = "Pulls the Secret from Openshift and pushes them to Cryptopus.\n" \
                      'If a Cryptopus Account in the selected folder using the name ' \
                      "of the given secret is already present, it will be updated accordingly.\n" \
                      'If no name is given, it will pull all secrets inside the selected project.'

      c.action do |args|
        TTY::Exit.exit_with(:usage_error, 'Only a single or no arguments are allowed') if args.length > 1

        execute_action({ secret_name: args.first }) do
          if args.empty?
            cry_adapter.save_secrets(OSESecret.all)
            puts 'Saved secrets of current project'
          elsif args.length == 1
            cry_adapter.save_secrets([OSESecret.find_by_name(args.first)])
            puts "Saved secret #{args.first}"
          end
        end
      end
    end

    command :'ose-secret-push' do |c|
      c.syntax = 'ccli ose secret push <secret-name>'
      c.summary = 'Pushes secret from Cryptopus to Openshift'
      c.description = 'Pushes the Secret to Openshift by retrieving it from Cryptopus first. ' \
                      'If a Secret in the selected Openshift project using the name ' \
                      'of the given accountname is already present, it will be updated accordingly.'

      c.action do |args|
        secret_name = args.first
        TTY::Exit.exit_with(:usage_error, 'Secret name is missing') unless secret_name
        TTY::Exit.exit_with(:usage_error, 'Only one secret can be pushed') if args.length > 1
        execute_action({ secret_name: secret_name }) do
          secret = cry_adapter.find_secret_account_by_name(secret_name)
          ose_adapter.insert_secret(Account.from_json(secret).to_osesecret)
        end
        puts 'Secret was successfully applied'
      end
    end

    run!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength

  private

  def execute_action(options = {})
    begin
      yield if block_given?
    rescue SessionMissingError
      TTY::Exit.exit_with(:usage_error, 'Not logged in')
    rescue UnauthorizedError
      TTY::Exit.exit_with(:usage_error, 'Authorization failed')
    rescue ForbiddenError
      TTY::Exit.exit_with(:usage_error, 'Access denied')
    rescue SocketError
      TTY::Exit.exit_with(:usage_error, 'Could not connect')
    rescue NoFolderSelectedError
      TTY::Exit.exit_with(:usage_error, 'Folder must be selected using ccli folder <id>')
    rescue OpenshiftClientMissingError
      TTY::Exit.exit_with(:usage_error, 'oc is not installed')
    rescue OpenshiftClientNotLoggedInError
      TTY::Exit.exit_with(:usage_error, 'oc is not logged in')
    rescue CryptopusAccountNotFoundError
      TTY::Exit.exit_with(:usage_error, 'secret with the given name ' \
                          "#{options.secret_name} was not found")
    end
  end

  def ose_adapter
    @ose_adapter ||= OSEAdapter.new
  end

  def cry_adapter
    @cry_adapter ||= CryAdapter.new
  end

  def session_adapter
    @cry_adapter ||= SessionAdapter.new
  end
end

CLI.new.run if $PROGRAM_NAME == __FILE__
