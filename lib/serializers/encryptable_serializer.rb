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
        'type' => encryptable.type }.to_yaml
    end

    def from_json(json)
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      Encryptable.new(name: attributes[:name],
                      username: attributes[:cleartext_username],
                      password: attributes[:cleartext_password],
                      type: attributes[:type],
                      id: data[:id])
    end
  end
end
