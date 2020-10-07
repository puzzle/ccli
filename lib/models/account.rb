# frozen_string_literal: true

class Account
  attr_reader :id, :accountname, :username, :password, :type, :ose_secret
  attr_accessor :folder

  def initialize(accountname: nil, username: nil, password: nil,
                 ose_secret: nil, type: nil, id: nil)
    @id = id
    @accountname = accountname
    @username = username
    @password = password
    @ose_secret = ose_secret
    @type = type || 'credentials'
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
      AccountSerializer.from_json(CryptopusAdapter.new.get("accounts/#{id}"))
    end

    def find_by_name_and_folder_id(name, id)
      Folder.find(id).accounts.find do |account|
        account.accountname.downcase == name.downcase
      end
    end

    def from_json(json)
      AccountSerializer.from_json(json)
    end
  end
end
