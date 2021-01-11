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
    program :version, '1.0.0'
    program :description, 'CLI tool to manage Openshift Secrets via Cryptopus'
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

    command :account do |c|
      c.syntax = 'cry account <id> [options]'
      c.description = 'Fetches an account by the given id'
      c.option '--username', String, 'Only show the username of the user'
      c.option '--password', String, 'Only show the password of the user'

      c.action do |args, options|
        exit_with_error(:usage_error, 'id missing') if args.empty?
        execute_action do
          logger.info 'Fetching account...'
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
        exit_with_error(:usage_error, 'id missing') unless id
        exit_with_error(:usage_error, 'id invalid') unless id.match?(/(^\d{1,10}$)/)

        execute_action do
          session_adapter.update_session({ folder: id })

          log_success "Selected Folder with id: #{id}"
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
          exit_with_error(:usage_error,
                          'Only a single or no arguments are allowed')
        end

        execute_action({ secret_name: args.first }) do
          if args.empty?
            logger.info 'Fetching secrets...'
            OSESecret.all.each do |secret|
              logger.info "Saving secret #{secret.name}..."
              cryptopus_adapter.save_secret(secret)
              log_success "Saved secret #{secret.name} in Cryptopus"
            end
          elsif args.length == 1
            logger.info "Saving secret #{args.first}..."
            cryptopus_adapter.save_secret(OSESecret.find_by_name(args.first))
            log_success "Saved secret #{args.first} in Cryptopus"
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
        exit_with_error(:usage_error, 'Only one secret can be pushed') if args.length > 1
        execute_action({ secret_name: secret_name }) do
          secret_accounts = if secret_name.nil?
                              logger.info 'Fetching all accounts in folder...'
                              session_adapter.selected_folder.accounts
                            else
                              logger.info "Fetching account #{secret_name}..."
                              [cryptopus_adapter.find_account_by_name(secret_name)]
                            end
          secret_accounts.each do |account|
            logger.info "Fetching secret #{account.accountname}..."
            secret_account = Account.find(account.id)
            logger.info "Inserting secret #{account.accountname}..."
            ose_adapter.insert_secret(secret_account.to_osesecret)
            log_success "Secret #{secret_account.accountname} was successfully applied"
          end
        end
      end
    end

    command :'k8s-secret-pull' do |c|
      c.syntax = 'cry k8s-secret-pull <secret-name>'
      c.summary = 'Pulls secret from Kubectl to Cryptopus'
      c.description = "Pulls the Secret from Kubectl and pushes them to Cryptopus.\n" \
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
            logger.info 'Fetching secrets...'
            K8SSecret.all.each do |secret|
              logger.info "Saving secret #{secret.name}..."
              cryptopus_adapter.save_secret(secret)
              log_success "Saved secret #{secret.name} in Cryptopus"
            end
          elsif args.length == 1
            logger.info "Saving secret #{args.first}..."
            cryptopus_adapter.save_secret(K8SSecret.find_by_name(args.first))
            log_success "Saved secret #{args.first} in Cryptopus"
          end
        end
      end
    end

    command :'k8s-secret-push' do |c|
      c.syntax = 'cry k8s-secret-push <secret-name>'
      c.summary = 'Pushes secret from Cryptopus to Kubectl'
      c.description = 'Pushes the Secret to Kubectl by retrieving it from Cryptopus first. ' \
                      'If a Secret in the selected Kubectl project using the name ' \
                      'of the given accountname is already present, it will be updated accordingly.'

      c.action do |args|
        secret_name = args.first
        exit_with_error(:usage_error, 'Only one secret can be pushed') if args.length > 1
        execute_action({ secret_name: secret_name }) do
          secret_accounts = if secret_name.nil?
                              logger.info 'Fetching all accounts in folder...'
                              session_adapter.selected_folder.accounts
                            else
                              logger.info "Fetching account #{secret_name}..."
                              [cryptopus_adapter.find_account_by_name(secret_name)]
                            end
          secret_accounts.each do |account|
            logger.info "Fetching secret #{account.accountname}..."
            secret_account = Account.find(account.id)
            logger.info "Inserting secret #{account.accountname}..."
            k8s_adapter.insert_secret(secret_account.to_osesecret)
            log_success "Secret #{secret_account.accountname} was successfully applied"
          end
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
  rescue OpenshiftClientMissingError
    exit_with_error(:usage_error, 'oc is not installed')
  rescue OpenshiftClientNotLoggedInError
    exit_with_error(:usage_error, 'oc is not logged in')
  rescue KubernetesClientMissingError
    exit_with_error(:usage_error, 'kubectl is not installed')
  rescue KubernetesClientNotLoggedInError
    exit_with_error(:usage_error, 'kubectl is not logged in')
  rescue CryptopusAccountNotFoundError
    exit_with_error(:usage_error, 'Secret with the given name ' \
                                  "#{options[:secret_name]} was not found")
  rescue OpenshiftSecretNotFoundError
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

  def ose_adapter
    @ose_adapter ||= OSEAdapter.new
  end

  def cryptopus_adapter
    @cryptopus_adapter ||= CryptopusAdapter.new
  end

  def session_adapter
    @session_adapter ||= SessionAdapter.new
  end

  def k8s_adapter
    @k8s_adapter ||= K8SAdapter.new
  end

  def renew_auth_token
    session_adapter.update_session({ token: cryptopus_adapter.renewed_auth_token })
  end
end
# rubocop:enable Metrics/ClassLength

CLI.new.run if $PROGRAM_NAME == __FILE__
