# frozen_string_literal: true

require_relative '../models/ose_secret'

class OSESecretSerializer
  class << self
    def from_yaml(yaml)
      OSESecret.new(yaml.dig(:metadata, :name), yaml.to_s)
    end

    def to_yaml(secret)
    end

    def to_account(secret)
      Account.new(secret.name, secret.name, secret.data, 'openshift_secret')
    end
  end
end
