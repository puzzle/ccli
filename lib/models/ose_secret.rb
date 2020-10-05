# frozen_string_literal: true

class OSESecret
  attr_reader :name, :data

  def initialize(name, data)
    @name = name
    @data = data
  end

  def to_account
    OSESecretSerializer.to_account(self)
  end

  def to_yaml
    OSESecretSerializer.to_yaml(self)
  end

  class << self
    def find_by_name(name)
      OSESecretSerializer.from_yaml(OSEAdapter.new.fetch_secret(name))
    end

    def all
      OSEAdapter.new.fetch_all_secrets.map { |s| OSESecretSerializer.from_yaml(s) }
    end

    def from_account(account)
      OSESecret.from_json(account)
    end
  end
end
