require 'spec_helper'

describe TeamPresenter do
  subject { described_class }

  let(:team) do
    Team.new(name: 'bbt', folders: [Folder.new(name: 'ruby', id: 1), Folder.new(name: 'java', id: 2)], id: 3)
  end

  context 'render_list' do
    it 'serializes team correctly' do
      output = subject.render_list(team)

      expect(output).to include('bbt => ruby (cry use bbt/ruby)')
      expect(output).to include('java (cry use bbt/java)')
    end

    it 'serializes team correctly and replaces spaces with dashes for use command' do
      team_with_spaces = Team.new(name: 'puzzle bbt',
                                  folders: [Folder.new(name: 'ruby lang', id: 1), Folder.new(name: 'java lang', id: 2)],
                                  id: 3)
      output = subject.render_list(team_with_spaces)

      expect(output).to include('puzzle bbt => ruby lang (cry use puzzle-bbt/ruby-lang)')
      expect(output).to include('java lang (cry use puzzle-bbt/java-lang)')
    end
  end
end
