# frozen_string_literal: true

class OSESecret
  def initialize(name, token)
    @name = name
    @token = token
  end

  def to_account
  end

  def to_yaml
    OSESecretSerializer.to_yaml(self)
  end

  class << self
    def retrieve(name)
    end

    def retrieve_all
    end

    def from_account(account)
    end
  end
end
