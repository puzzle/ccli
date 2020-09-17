# frozen_string_literal: true

require 'models/ose_secret'
require 'psych'
require 'models/ose_secret'

class OSESecretSerializer
  class << self
    def from_yaml(yaml)
      secret_hash = Psych.load(yaml, symbolize_names: true)
      OSESecret.new(secret_hash.dig(:metadata, :name), yaml)
    end

    def to_account(secret)
      Account.new(secret.name, secret.name, secret.data, 'openshift_secret')
    end
  end
end
