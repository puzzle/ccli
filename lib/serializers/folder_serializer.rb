# frozen_string_literal: true

class FolderSerializer
  class << self
    def from_json(json)
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      Folder.new(attributes[:name], id: data[:id])
    end
  end
end
