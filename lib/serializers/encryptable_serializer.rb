# frozen_string_literal: true

require 'yaml'

class EncryptableSerializer
  class << self
    # rubocop:disable Metrics/MethodLength
    def to_json(encryptable)
      {
        data: {
          type: 'encryptables',
          id: encryptable.id,
          attributes: {
            name: encryptable.name,
            type: encryptable.type,
            cleartext_username: encryptable.username,
            cleartext_password: encryptable.password,
            cleartext_pin: encryptable.pin,
            cleartext_token: encryptable.token,
            cleartext_email: encryptable.email,
            cleartext_custom_attr: encryptable.custom_attr
          },
          relationships: {
            folder: {
              data: {
                id: encryptable.folder,
                type: 'folders'
              }
            }
          }
        }
      }.compact.to_json
    end
    # rubocop:enable Metrics/MethodLength

    def to_yaml(encryptable)
      { 'id' => encryptable.id,
        'name' => encryptable.name,
        'username' => encryptable.username,
        'password' => encryptable.password,
        'pin' => encryptable.pin,
        'token' => encryptable.token,
        'email' => encryptable.email,
        'customAttribute' => encryptable.custom_attr,
        'type' => encryptable.type }.to_yaml
    end

    def from_json(json)
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      Encryptable.new(name: attributes[:name], username: attributes[:cleartext_username],
                      password: attributes[:cleartext_password], pin: attributes[:cleartext_pin],
                      token: attributes[:cleartext_token], email: attributes[:cleartext_email],
                      custom_attr: attributes[:cleartext_custom_attr], type: attributes[:type],
                      id: data[:id])
    end
  end
end
