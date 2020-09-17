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
            category: account.category,
            cleartext_username: account.username,
            cleartext_password: account.password
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
        'category' => account.category }.to_yaml
    end

    def from_json(json)
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      Account.new(attributes[:accountname],
                  attributes[:cleartext_username],
                  attributes[:cleartext_password],
                  attributes[:category],
                  id: data[:id])
    end

    def to_osesecret(account)
      OSESecret.new(account.accountname, account.password)
    end
  end
end
