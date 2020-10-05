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

  class << self
    def all
      response = JSON.parse(CryAdapter.new.get('teams'), symbolize_names: true)
      response[:data].map do |team|
        TeamSerializer.from_json(team.to_json, folders_json: included_folders(response))
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
