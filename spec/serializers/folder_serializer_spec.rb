require 'spec_helper'

describe FolderSerializer do
  subject { described_class }
  let(:folder_json) do
    {
      data: {
        id: 1,
        attributes: {
          name: 'ruby',
        }
      }
    }.to_json
  end

  context 'from_json' do
    it 'serializes json to correct folder' do
      folder = subject.from_json(folder_json)

      expect(folder.name).to eq('ruby')
      expect(folder.id).to eq(1)
    end
  end
end
