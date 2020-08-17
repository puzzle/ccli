# frozen_string_literal: true

require_relative '../models/account'
require 'yaml'

class AccountSerializer
  class << self
    def to_json(account)
    end

    def to_yaml(account)
      { 'id' => account.id,
        'accountname' => account.accountname,
        'username' => account.username,
        'password' => account.password,
        'category' => account.category }.to_yaml
    end

    def from_json(json)
      data = json['data']
      attributes = data['attributes']
      Account.new(data['id'],
                  attributes['accountname'],
                  attributes['cleartext_username'],
                  attributes['cleartext_password'],
                  attributes['category'])
    end
  end
end
