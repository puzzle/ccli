# frozen_string_literal: true

class OSESecret
  attr_reader :name, :ose_secret

  def initialize(name, ose_secret)
    @name = name
    @ose_secret = ose_secret
  end

  def to_account
    OSESecretSerializer.to_account(self)
  end

  def to_yaml
    OSESecretSerializer.to_yaml(self)
  end

  private

  def encoded_data(data)
    data.transform_values do |value|
      Base64.strict_encode64(value)
    rescue ArgumentError
      value
    end
  end

  class << self
    def from_yaml(yaml)
      OSESecretSerializer.from_yaml(yaml)
    end

    def find_by_name(name)
      OSESecretSerializer.from_yaml(OSEAdapter.new.fetch_secret(name))
    end

    def all
      OSEAdapter.new.fetch_all_secrets.map { |s| OSESecretSerializer.from_yaml(s) }
    end
  end
end
