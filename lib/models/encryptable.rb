# frozen_string_literal: true

class Encryptable
  attr_reader :id, :name, :username, :password, :pin, :token, :email, :custom_attr, :type
  attr_accessor :folder

  def initialize(params = {})
    @id = params[:id]
    @name = params[:name]
    @username = params[:username]
    @password = params[:password]
    @pin = params[:pin]
    @token = params[:token]
    @email = params[:email]
    @custom_attr = params[:custom_attr]
    @type = params[:type] || 'credentials'
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
