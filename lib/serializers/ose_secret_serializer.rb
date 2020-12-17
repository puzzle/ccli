# frozen_string_literal: true

require 'psych'
require 'base64'

class OSESecretSerializer
  class << self
    # rubocop:disable Metrics/MethodLength
    def from_yaml(yaml)
      secret_hash = Psych.load(yaml)
      data = {
        'apiVersion' => secret_hash['apiVersion'],
        'data' => decoded_data(secret_hash['data']),
        'kind' => secret_hash['kind'],
        'metadata' => {
          'name' => secret_hash['metadata']['name'],
          'labels' => secret_hash['metadata']['labels']
        }
      }.to_yaml
      OSESecret.new(secret_hash['metadata']['name'], data.to_s)
    end
    # rubocop:enable Metrics/MethodLength

    def to_account(secret)
      Account.new(accountname: secret.name, ose_secret: secret.ose_secret, type: 'ose_secret')
    end

    private

    def decoded_data(data)
      data.transform_values do |value|
        Base64.strict_decode64(value)
      end
    end
  end
end
