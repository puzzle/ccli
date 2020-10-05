# frozen_string_literal: true

class TeamSerializer
  class << self
    def from_json(json, folders_json: [])
      json = JSON.parse(json, symbolize_names: true)
      data = json[:data] || json
      attributes = data[:attributes]
      folder_ids = data[:relationships][:folders][:data].map { |folder| folder[:id] }
      folders = folders_json.map do |folder|
        FolderSerializer.from_json(folder.to_json) if folder_ids.include?(folder[:id])
      end.compact
      Team.new(name: attributes[:name],
               folders: folders,
               id: data[:id])
    end
  end
end
