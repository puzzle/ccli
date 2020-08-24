# frozen_string_literal: true

require 'tty-command'

class OSEAdapter
  def fetch_secret(name)
    raise OpenshiftClientMissingError unless oc_installed?
    raise OpenshiftClientNotLoggedInError unless oc_logged_in?

    begin
      out, _err = cmd.run("oc get -o yaml secret #{name}")
      Psych.load(out, symbolize_names: true)
    rescue TTY::Command::ExitError
      raise OpenshiftSecretNotFoundError
    end
  end

  def fetch_all_secrets
    raise OpenshiftClientMissingError unless oc_installed?
    raise OpenshiftClientNotLoggedInError unless oc_logged_in?

    cmd.run('oc get secret -o custom-columns=NAME:metadata.name ' \
            '--no-headers=true').map do |secret|
      fetch_secret(secret)
    end
  end

  def insert_secret(yaml)
  end

  private

  def oc_installed?
    cmd.run!('which oc').success?
  end

  def oc_logged_in?
    cmd.run!('oc project').success?
  end

  def cmd
    @cmd ||= TTY::Command.new(printer: :null)
  end
end
