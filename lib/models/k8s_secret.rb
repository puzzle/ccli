# frozen_string_literal: true

require_relative './ose_secret'

class K8SSecret < OSESecret
  class << self
    def all
      K8SAdapter.new.fetch_all_secrets.map { |s| OSESecretSerializer.from_yaml(s) }
    end
  end
end
