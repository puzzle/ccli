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

    def to_yaml(secret)
      secret_hash = Psych.load(secret.ose_secret)
      secret_hash['data'] = encoded_data(secret_hash['data'])
      secret_hash.to_yaml
    end

    private

    def decoded_data(data)
      return {} unless data

      data.transform_values do |value|
        Base64.strict_decode64(value)
      rescue ArgumentError
        value
      end
    end

    def encoded_data(data)
      return {} unless data

      data.transform_values do |value|
        Base64.strict_encode64(value)
      end
    end
  end
end
