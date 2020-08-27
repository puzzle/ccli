# frozen_string_literal: true

require_relative '../errors'
require_relative '../adapters/session_adapter'
require_relative '../serializers/account_serializer'

class Account
  attr_reader :id, :accountname, :username, :password, :category
  attr_accessor :folder

  def initialize(accountname, username, password, category, id: nil)
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
    AccountSerializer.to_osesecret(self)
  end

  class << self
    def find(id)
      AccountSerializer.from_json(CryAdapter.new.get("accounts/#{id}"))
    end

    def from_json(json)
      AccountSerializer.from_json(json)
    end
  end
end
