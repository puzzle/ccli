# frozen_string_literal: true

require 'models/account'
require 'models/ose_secret'
require 'models/account'
require 'yaml'

class AccountSerializer
  class << self
    # rubocop:disable Metrics/MethodLength
    def to_json(account)
      {
        data: {
          type: 'accounts',
          id: account.id,
          attributes: {
            accountname: account.accountname,
            type: account.type,
            cleartext_username: account.username,
            cleartext_password: account.password,
            ose_secret: account.ose_secret
          },
          relationships: {
            folder: {
              data: {
                id: account.folder,
                type: 'folders'
              }
            }
          }
        }
      }.compact.to_json
    end
    # rubocop:enable Metrics/MethodLength

    def to_yaml(account)
      { 'id' => account.id,
        'accountname' => account.accountname,
        'username' => account.username,
        'password' => account.password,
        'type' => account.type }.to_yaml
    end

    def from_json(json)
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      Account.new(accountname: attributes[:accountname],
                  username: attributes[:cleartext_username],
                  password: attributes[:cleartext_password],
                  ose_secret: attributes[:ose_secret],
                  type: attributes[:type],
                  id: data[:id])
    end

    def to_osesecret(account)
      OSESecret.new(account.accountname, account.ose_secret)
    end
  end
end
