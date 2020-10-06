# frozen_string_literal: true

require 'rubygems'
require 'commander'
require 'tty-exit'

Dir[File.join(__dir__, '**', '*.rb')].sort.each { |file| require file }

class CLI
  include Commander::Methods

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity
  def run
    program :name, 'cry - cryptopus cli'
    program :version, '1.0.0'
    program :description, 'CLI tool to manage Openshift Secrets via Cryptopus'
    program :help, 'Source Code', 'https://www.github.com/puzzle/ccli'
    program :help, 'Usage', 'cry [flags]'

    command :login do |c|
      c.syntax = 'cry login <credentials>'
      c.description = 'Logs in to the ccli'

      c.action do |args|
        TTY::Exit.exit_with(:usage_error, 'Credentials missing') if args.empty?
        token, url = args.first.split('@')
        TTY::Exit.exit_with(:usage_error, 'URL missing') unless url
        TTY::Exit.exit_with(:usage_error, 'Token missing') if token.empty?
        execute_action do
          session_adapter.update_session({ encoded_token: token, url: url })
          puts 'Successfully logged in'
        end
      end
    end

    command :logout do |c|
      c.syntax = 'cry logout'
      c.description = 'Logs out of the ccli'

      c.action do
        execute_action do
          session_adapter.clear_session
          puts 'Successfully logged out'
        end
      end
    end

    command :account do |c|
      c.syntax = 'cry account <id> [options]'
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
      c.syntax = 'cry folder <id>'
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
      c.syntax = 'cry ose-secret-pull <secret-name>'
      c.summary = 'Pulls secret from Openshift to Cryptopus'
      c.description = "Pulls the Secret from Openshift and pushes them to Cryptopus.\n" \
                      'If a Cryptopus Account in the selected folder using the name ' \
                      "of the given secret is already present, it will be updated accordingly.\n" \
                      'If no name is given, it will pull all secrets inside the selected project.'

      c.action do |args|
        if args.length > 1
          TTY::Exit.exit_with(:usage_error,
                              'Only a single or no arguments are allowed')
        end

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
      c.syntax = 'cry ose-secret-push <secret-name>'
      c.summary = 'Pushes secret from Cryptopus to Openshift'
      c.description = 'Pushes the Secret to Openshift by retrieving it from Cryptopus first. ' \
                      'If a Secret in the selected Openshift project using the name ' \
                      'of the given accountname is already present, it will be updated accordingly.'

      c.action do |args|
        secret_name = args.first
        TTY::Exit.exit_with(:usage_error, 'Secret name is missing') unless secret_name
        TTY::Exit.exit_with(:usage_error, 'Only one secret can be pushed') if args.length > 1
        execute_action({ secret_name: secret_name }) do
          secret_account = cry_adapter.find_account_by_name(secret_name)
          ose_adapter.insert_secret(secret_account.to_osesecret)
        end
        puts 'Secret was successfully applied'
      end
    end

    command :teams do |c|
      c.syntax = 'cry teams'
      c.description = 'Lists all available teams'

      c.action do
        execute_action do
          teams = Team.all
          output = teams.map(&:render_list).join("\n")
          puts output
        end
      end
    end

    command :use do |c|
      c.syntax = 'cry use <team/folder>'
      c.description = 'Select the current folder'

      c.action do |args|
        team_name, folder_name = extract_use_args(args)
        execute_action({ team_name: team_name, folder_name: folder_name }) do
          selected_team = Team.find_by_name(team_name)
          raise TeamNotFoundError unless selected_team

          selected_folder = selected_team.folder_by_name(folder_name)
          raise FolderNotFoundError unless selected_folder

          session_adapter.update_session({ folder: selected_folder.id })
          puts "Selected folder #{folder_name.downcase} in team #{team_name.downcase}"
        end
      end
    end

    run!
  end

  private

  def execute_action(options = {})
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
    TTY::Exit.exit_with(:usage_error, 'Folder must be selected using cry folder <id>')
  rescue OpenshiftClientMissingError
    TTY::Exit.exit_with(:usage_error, 'oc is not installed')
  rescue OpenshiftClientNotLoggedInError
    TTY::Exit.exit_with(:usage_error, 'oc is not logged in')
  rescue CryptopusAccountNotFoundError
    TTY::Exit.exit_with(:usage_error, 'secret with the given name ' \
                        "#{options[:secret_name]} was not found")
  rescue OpenshiftSecretNotFoundError
    TTY::Exit.exit_with(:usage_error, 'secret with the given name ' \
                        "#{options[:secret_name]} was not found")
  rescue TeamNotFoundError
    TTY::Exit.exit_with(:usage_error, 'Team with the given name ' \
                        "#{options[:team_name]} was not found")
  rescue FolderNotFoundError
    TTY::Exit.exit_with(:usage_error, 'Folder with the given name ' \
                        "#{options[:folder_name]} was not found")
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity

  def extract_use_args(args)
    usage_info = 'Usage: cry use <team/folder>'

    TTY::Exit.exit_with(:usage_error, "Arguments missing\n#{usage_info}") unless args.length >= 1
    team_name, folder_name = args.first.split('/').map(&:downcase)
    TTY::Exit.exit_with(:usage_error, "Team name is missing\n#{usage_info}") if team_name.empty?
    TTY::Exit.exit_with(:usage_error, "Folder name is missing\n#{usage_info}") unless folder_name
    [team_name, folder_name]
  end

  def ose_adapter
    @ose_adapter ||= OSEAdapter.new
  end

  def cry_adapter
    @cry_adapter ||= CryAdapter.new
  end

  def session_adapter
    @session_adapter ||= SessionAdapter.new
  end
end

CLI.new.run if $PROGRAM_NAME == __FILE__
