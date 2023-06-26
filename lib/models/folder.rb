# frozen_string_literal: true

class Folder
  attr_reader :name, :id, :encryptables

  def initialize(name: nil, id: nil, encryptables: [])
    @name = name
    @id = id
    @encryptables = encryptables
  end

  class << self
    def find(id)
      json = JSON.parse(CryptopusAdapter.new.get("folders/#{id}"),
                        symbolize_names: true)
      included = json[:included] || []
      name = json[:data][:attributes][:name]
      encryptables = included.map do |record|
        Encryptable.from_json(record.to_json) if %w[encryptable_credentials].include? record[:type]
      end.compact
      Folder.new(id: id, name: name, encryptables: encryptables)
    end
  end
end
