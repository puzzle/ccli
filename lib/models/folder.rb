# frozen_string_literal: true

class Folder
  attr_reader :name, :id, :accounts

  def initialize(name: nil, id: nil, accounts: [])
    @name = name
    @id = id
    @accounts = accounts
  end

  class << self
    def find(id)
      json = JSON.parse(CryptopusAdapter.new.get("folders/#{id}"),
                        symbolize_names: true)
      included = json[:included] || []
      name = json[:data][:attributes][:name]
      accounts = included.map do |record|
        Account.from_json(record.to_json) if %w[account_ose_secrets
                                                account_credentials].include? record[:type]
      end.compact
      Folder.new(id: id, name: name, accounts: accounts)
    end
  end
end
