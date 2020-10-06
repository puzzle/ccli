require 'spec_helper'

describe TeamSerializer do
  subject { described_class }
  let(:team_json) do
    {
      data: {
        id: 1,
        attributes: {
          name: 'bbt',
        },
        relationships: {
          folders: {
            data: [
              {
                id: 2
              },
              {
                id: 3
              }
            ]
          }
        }
      }
    }.to_json
  end

  let(:included_folders) do
    [
      {
        type: 'folders',
        id: 2,
        attributes: {
          name: 'ruby'
        }
      },
      {
        type: 'folders',
        id: 3,
        attributes: {
          name: 'java'
        }
      }
    ]
  end

  let(:team) do
    Team.new(name: 'bbt', folders: [Folder.new(name: 'ruby', id: 1), Folder.new(name: 'java', id: 2)], id: 3)
  end

  context 'from_json' do
    it 'serializes json to correct team and its folders' do
      team = subject.from_json(team_json, folders_json: included_folders)

      expect(team.name).to eq('bbt')
      expect(team.folders.count).to eq(2)
      expect(team.folders[0].name).to eq('ruby')
      expect(team.folders[1].name).to eq('java')
      expect(team.id).to eq(1)
    end
  end
end
