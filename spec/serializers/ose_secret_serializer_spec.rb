require 'spec_helper'

describe OSESecretSerializer do
  subject { described_class }
  let(:secret_yaml) do
    {
      'apiVersion' => 'v1',
      'data' => {
        'token' => 'very secret token'
      },
      'kind' => 'Secret',
      'metadata' => {
        'name' => 'spec_secret',
        'labels' => 'cryptopus-sync=true'
      }
    }.to_yaml
  end

  context 'from_yaml' do
    it 'serializes yaml to correct secret' do
      secret = subject.from_yaml(secret_yaml)

      expect(secret.name).to eq('spec_secret')
      expect(secret.ose_secret).to eq(secret_yaml)
    end
  end

  context 'to_account' do
    it 'serializes secret to correct account' do
      secret = OSESecret.new('spec_secret', secret_yaml)

      account = subject.to_account(secret)

      expect(account.accountname).to eq('spec_secret')
      expect(account.ose_secret).to eq(secret_yaml)
      expect(account.type).to eq('ose_secret')
    end
  end
end
