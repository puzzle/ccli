# frozen_string_literal: true

class Encryptable
  attr_reader :id, :name, :username, :password, :pin, :token, :email, :custom_attr, :type
  attr_accessor :folder

  def initialize(name: nil, username: nil, password: nil,
                 pin: nil, token: nil, email: nil, custom_attr: nil,
                 type: nil, id: nil)
    @id = id
    @name = name
    @username = username
    @password = password
    @pin = pin
    @token = token
    @email = email
    @custom_attr = custom_attr
    @type = type || 'credentials'
  end

  def to_json(*_args)
    EncryptableSerializer.to_json(self)
  end

  def to_yaml
    EncryptableSerializer.to_yaml(self)
  end

  class << self
    def find(id)
      EncryptableSerializer.from_json(CryptopusAdapter.new.get("encryptables/#{id}"))
    end

    def find_by_name_and_folder_id(name, id)
      Folder.find(id).encryptables.find do |encryptable|
        encryptable.name.downcase == name.downcase
      end
    end

    def from_json(json)
      EncryptableSerializer.from_json(json)
    end
  end
end
