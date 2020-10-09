# frozen_string_literal: true

require 'tty-command'
require_relative './cluster_secret_adapter'

class K8SAdapter < ClusterSecretAdapter
  private

  def client
    'kubectl'
  end

  def client_missing_error
    KubernetesClientMissingError
  end

  def client_not_logged_in_error
    KubernetesClientNotLoggedInError
  end
end
