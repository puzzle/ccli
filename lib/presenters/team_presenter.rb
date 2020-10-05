# frozen_string_literal: true

class TeamPresenter
  class << self
    def render_list(team)
      team_name = team.name.downcase
      despaced_team_name = team_name.gsub(' ', '-')
      folder_rows = team.folders.map do |folder|
        folder_name = folder.name.downcase
        "#{folder_name} (cry use #{despaced_team_name}/#{folder_name.gsub(' ', '-')})"
      end

      team_name = "#{team_name} => "
      joined_folder_rows = folder_rows.join("\n" + ' ' * team_name.length)
      team_name + joined_folder_rows
    end
  end
end
