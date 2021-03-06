# frozen_string_literal: true

require 'tty-command'
require_relative './cluster_secret_adapter'

class OSEAdapter < ClusterSecretAdapter
  private

  def client
    'oc'
  end

  def client_missing_error
    OpenshiftClientMissingError
  end

  def client_not_logged_in_error
    OpenshiftClientNotLoggedInError
  end
end
