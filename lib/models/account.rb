# frozen_string_literal: true

require_relative '../errors'
require_relative '../adapters/session_adapter'
require_relative '../serializers/account_serializer'

class Account
  attr_reader :id, :accountname, :username, :password, :category

  def initialize(id, accountname, username, password, category)
    @id = id
    @accountname = accountname
    @username = username
    @password = password
    @category = category
  end

  def to_json(*_args)
    AccountSerializer.to_json(self)
  end

  def to_yaml
    AccountSerializer.to_yaml(self)
  end

  def to_osesecret
  end

  def self.find(id)
    AccountSerializer.from_json(CryAdapter.new.get('accounts', id))
  end
end
