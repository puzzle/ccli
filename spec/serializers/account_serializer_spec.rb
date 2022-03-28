require 'spec_helper'

describe EncryptableSerializer do
  subject { described_class }
  context 'to_json' do
    it 'serializes encryptable to correct json' do
      encryptable = Encryptable.new(name: 'spec_encryptable', username: 'spec_encryptable',
                                password: 'xAherfEDa21)sd', type: 'credentials', id: 1)
      encryptable.folder = 2
      json = subject.to_json(encryptable)


      serialized_encryptable = JSON.parse(json, symbolize_names: true)

      data = serialized_encryptable[:data]
      attributes = data[:attributes]
      folder = data[:relationships][:folder][:data]

      expect(attributes[:name]).to eq(encryptable.name)
      expect(attributes[:cleartext_username]).to eq(encryptable.username)
      expect(attributes[:cleartext_password]).to eq(encryptable.password)
      expect(attributes[:type]).to eq(encryptable.type)
      expect(data[:id]).to eq(encryptable.id)
      expect(folder[:id]).to eq(encryptable.folder)
    end
  end

  context 'to_yaml' do
    it 'serializes encryptable to correct yaml' do
      encryptable = Encryptable.new(name: 'spec_encryptable', username: 'spec_encryptable',
                                password: 'xAherfEDa21)sd', type: 'credentials', id: 1)
      json = subject.to_yaml(encryptable)

      serialized_encryptable = Psych.load(json)

      expect(serialized_encryptable['name']).to eq(encryptable.name)
      expect(serialized_encryptable['username']).to eq(encryptable.username)
      expect(serialized_encryptable['password']).to eq(encryptable.password)
      expect(serialized_encryptable['type']).to eq(encryptable.type)
      expect(serialized_encryptable['id']).to eq(encryptable.id)
    end
  end

  context 'from_json' do
    it 'serializes json to correct accont' do
      json = {
        data: {
          type: 'encryptables',
          id: 1,
          attributes: {
            name: 'spec_encryptable',
            type: 'credentials',
            cleartext_username: 'spec_encryptable',
            cleartext_password: 'xAherfEDa21)sd'
          },
          relationships: {
            folder: {
              data: {
                id: 2,
                type: 'folders'
              }
            }
          }
        }
      }.to_json

      encryptable = subject.from_json(json)

      expect(encryptable).to be_a Encryptable
      expect(encryptable.id).to eq(1)
      expect(encryptable.name).to eq('spec_encryptable')
      expect(encryptable.username).to eq('spec_encryptable')
      expect(encryptable.password).to eq('xAherfEDa21)sd')
      expect(encryptable.type).to eq('credentials')
    end
  end
end
