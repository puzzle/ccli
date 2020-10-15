# frozen_string_literal: true

class Team
  attr_reader :name, :id, :folders

  def initialize(name: nil, folders: nil, id: nil)
    @name = name
    @folders = folders
    @id = id
  end

  def render_list
    TeamPresenter.render_list(self)
  end

  def folder_by_name(name)
    folders.find do |folder|
      folder.name.downcase.gsub(' ', '-') == name.downcase
    end
  end

  class << self
    def all
      cryptopus_adapter = CryptopusAdapter.new
      response = JSON.parse(cryptopus_adapter.get('teams'), symbolize_names: true)
      response[:data].map do |team|
        TeamSerializer.from_json(team.to_json, folders_json: included_folders(response))
      end
    end

    def find_by_name(name)
      Team.all.find do |team|
        team.name.downcase.gsub(' ', '-') == name.downcase
      end
    end

    private

    def included_folders(json)
      json[:included].select do |folder|
        folder[:type] == 'folders'
      end
    end
  end
end
