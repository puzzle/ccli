# frozen_string_literal: true

require 'psych'

class OSESecretSerializer
  class << self
    def from_yaml(yaml)
      secret_hash = Psych.load(yaml, symbolize_names: true)
      OSESecret.new(secret_hash.dig(:metadata, :name), yaml)
    end

    def to_account(secret)
      Account.new(accountname: secret.name, ose_secret: secret.ose_secret, type: 'ose_secret')
    end
  end
end
