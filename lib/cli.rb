# frozen_string_literal: true

require 'rubygems'
require 'commander'
require 'tty-exit'
require 'tty-logger'

Dir[File.join(__dir__, '**', '*.rb')].sort.each { |file| require file }

# rubocop:disable Metrics/ClassLength
class CLI
  include Commander::Methods

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
  def run
    program :name, 'cry - cryptopus cli'
    program :version, '1.1.0'
    program :description, 'Command Line Client for Cryptopus'
    program :help, 'Source Code', 'https://www.github.com/puzzle/ccli'
    program :help, 'Usage', 'cry [flags]'

    command :login do |c|
      c.syntax = 'cry login <credentials>'
      c.description = 'Logs in to the ccli'

      c.action do |args|
        token, url = extract_login_args(args)
        execute_action do
          session_adapter.update_session({ encoded_token: token, url: url })
          renew_auth_token

          # Test authentification by calling teams endpoint
          Team.all

          log_success 'Successfully logged in'
        end
      end
    end

    command :logout do |c|
      c.syntax = 'cry logout'
      c.description = 'Logs out of the ccli'

      c.action do
        execute_action do
          session_adapter.clear_session
          log_success 'Successfully logged out'
        end
      end
    end

    command :encryptable do |c|
      c.syntax = 'cry encryptable <id> [options]'
      c.description = 'Fetches an encryptable by the given id'
      c.option '--username', String, 'Only show the username of the user'
      c.option '--password', String, 'Only show the password of the user'

      c.action do |args, options|
        exit_with_error(:usage_error, 'id missing') if args.empty?
        execute_action do
          logger.info 'Fetching encryptable...'
          encryptable = Encryptable.find(args.first)
          out = encryptable.username if options.username
          out = encryptable.password if options.password
          puts out || encryptable.to_yaml
        end
      end
    end

    command :folder do |c|
      c.syntax = 'cry folder <id>'
      c.description = 'Selects the Cryptopus folder by id'

      c.action do |args|
        id = args.first
        exit_with_error(:usage_error, 'id missing') unless id
        exit_with_error(:usage_error, 'id invalid') unless id.match?(/(^\d{1,10}$)/)

        execute_action do
          session_adapter.update_session({ folder: id })

          log_success "Selected Folder with id: #{id}"
        end
      end
    end

    command :teams do |c|
      c.syntax = 'cry teams'
      c.description = 'Lists all available teams'

      c.action do
        execute_action do
          logger.info 'Fetching teams...'
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
          logger.info "Looking for team #{team_name}..."
          selected_team = Team.find_by_name(team_name)
          raise TeamNotFoundError unless selected_team

          logger.info "Looking for folder #{folder_name}..."
          selected_folder = selected_team.folder_by_name(folder_name)
          raise FolderNotFoundError unless selected_folder

          session_adapter.update_session({ folder: selected_folder.id })
          log_success "Selected folder #{folder_name.downcase} in team #{team_name.downcase}"
        end
      end
    end

    run!
  end

  private

  def execute_action(options = {})
    yield if block_given?
  rescue SessionMissingError
    exit_with_error(:usage_error, 'Not logged in')
  rescue UnauthorizedError
    exit_with_error(:usage_error, 'Authorization failed')
  rescue ForbiddenError
    exit_with_error(:usage_error, 'Access denied')
  rescue SocketError
    exit_with_error(:usage_error, 'Could not connect')
  rescue NoFolderSelectedError
    exit_with_error(:usage_error, 'Folder must be selected using cry folder <id>')
  rescue CryptopusEncryptableNotFoundError
    exit_with_error(:usage_error, 'Secret with the given name ' \
                                  "#{options[:secret_name]} was not found")
  rescue TeamNotFoundError
    exit_with_error(:usage_error, 'Team with the given name ' \
                                  "#{options[:team_name]} was not found")
  rescue FolderNotFoundError
    exit_with_error(:usage_error, 'Folder with the given name ' \
                                  "#{options[:folder_name]} was not found")
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metric/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength


  def extract_login_args(args)
    exit_with_error(:usage_error, 'Credentials missing') if args.empty?
    token, url = args.first.split('@')
    exit_with_error(:usage_error, 'URL missing') unless url
    exit_with_error(:usage_error, 'Token missing') if token.empty?
    [token, url]
  end

  def extract_use_args(args)
    usage_info = 'Usage: cry use <team/folder>'

    exit_with_error(:usage_error, "Arguments missing\n#{usage_info}") unless args.length >= 1
    team_name, folder_name = args.first.split('/').map(&:downcase)
    exit_with_error(:usage_error, "Team name is missing\n#{usage_info}") if team_name.empty?
    exit_with_error(:usage_error, "Folder name is missing\n#{usage_info}") unless folder_name
    [team_name, folder_name]
  end

  def exit_with_error(error, msg)
    logger = TTY::Logger.new do |config|
      config.output = $stderr
    end
    logger.error(msg)
    TTY::Exit.exit_with(error)
  end

  def log_success(msg)
    logger = TTY::Logger.new do |config|
      config.output = $stdout
    end
    logger.success msg
  end

  def logger
    @logger ||= TTY::Logger.new
  end

  def cryptopus_adapter
    @cryptopus_adapter ||= CryptopusAdapter.new
  end

  def session_adapter
    @session_adapter ||= SessionAdapter.new
  end

  def renew_auth_token
    session_adapter.update_session({ token: cryptopus_adapter.renewed_auth_token })
  end
end
# rubocop:enable Metrics/ClassLength

CLI.new.run if $PROGRAM_NAME == __FILE__
