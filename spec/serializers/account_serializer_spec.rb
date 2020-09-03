require 'spec_helper'

describe AccountSerializer do
  subject { described_class }
  context 'to_json' do
    it 'serializes account to correct json' do
      account = Account.new('spec_account', 'spec_account', 'xAherfEDa21)sd', 'regular', id: 1)
      account.folder = 2
      json = subject.to_json(account)


      serialized_account = JSON.parse(json, symbolize_names: true)

      data = serialized_account[:data]
      attributes = data[:attributes]
      folder = data[:relationships][:folder][:data]

      expect(attributes[:accountname]).to eq(account.accountname)
      expect(attributes[:cleartext_username]).to eq(account.username)
      expect(attributes[:cleartext_password]).to eq(account.password)
      expect(attributes[:category]).to eq(account.category)
      expect(data[:id]).to eq(account.id)
      expect(folder[:id]).to eq(account.folder)
    end
  end

  context 'to_yaml' do
    it 'serializes account to correct yaml' do
      account = Account.new('spec_account', 'spec_account', 'xAherfEDa21)sd', 'regular', id: 1)
      json = subject.to_yaml(account)

      serialized_account = Psych.load(json)

      expect(serialized_account['accountname']).to eq(account.accountname)
      expect(serialized_account['username']).to eq(account.username)
      expect(serialized_account['password']).to eq(account.password)
      expect(serialized_account['category']).to eq(account.category)
      expect(serialized_account['id']).to eq(account.id)
    end
  end

  context 'from_json' do
    it 'serializes json to correct accont' do
      json = {
        data: {
          type: 'accounts',
          id: 1,
          attributes: {
            accountname: 'spec_account',
            category: 'regular',
            cleartext_username: 'spec_account',
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

      account = subject.from_json(json)

      expect(account).to be_a Account
      expect(account.id).to eq(1)
      expect(account.accountname).to eq('spec_account')
      expect(account.username).to eq('spec_account')
      expect(account.password).to eq('xAherfEDa21)sd')
      expect(account.category).to eq('regular')
    end
  end
end
