# frozen_string_literal: true

class Account
  def initialize(id, accountname, password, type)
    @id = id
    @accountname = accountname
    @password = password
    @type = type
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
  end
end
