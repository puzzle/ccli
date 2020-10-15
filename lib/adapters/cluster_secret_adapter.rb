# frozen_string_literal: true

require 'tty-command'

class ClusterSecretAdapter

  CCLI_FLAG_LABEL = 'cryptopus-sync'

  def fetch_secret(name)
    raise client_missing_error unless client_installed?
    raise client_not_logged_in_error unless client_logged_in?

    begin
      out, _err = cmd.run("#{client} get -o yaml secret --field-selector='metadata.name=#{name}' " \
                          "-l #{CCLI_FLAG_LABEL}=true")

      Psych.load(out)['items'].first.to_yaml
    rescue TTY::Command::ExitError
      raise OpenshiftSecretNotFoundError
    end
  end

  def fetch_all_secrets
    raise client_missing_error unless client_installed?
    raise client_not_logged_in_error unless client_logged_in?

    secrets, _err = cmd.run("#{client} get secret -o yaml -l #{CCLI_FLAG_LABEL}=true")
    Psych.load(secrets)['items'].map do |secret|
      secret.to_yaml
    end
  end

  def insert_secret(secret)
    raise client_missing_error unless client_installed?
    raise client_not_logged_in_error unless client_logged_in?

    File.open("/tmp/#{secret.name}.yml", 'w') do |file|
      file.write secret.ose_secret
    end

    cmd.run("#{client} delete -f /tmp/#{secret.name}.yml --ignore-not-found=true")
    cmd.run("#{client} create -f /tmp/#{secret.name}.yml")
  end

  private

  def client_installed?
    cmd.run!("which #{client}").success?
  end

  def client_logged_in?
    cmd.run!("#{client} get secret").success?
  end

  def cmd
    @cmd ||= TTY::Command.new(printer: :null)
  end

  def client
    raise 'implement in subclass'
  end

  def client_missing_error
    raise 'implement in subclass'
  end

  def client_not_logged_in_error
    raise 'implement in subclass'
  end
end
