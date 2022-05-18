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

  context 'to_encryptable' do
    it 'serializes secret to correct encryptable' do
      secret = OSESecret.new('spec_secret', secret_yaml)

      encryptable = subject.to_encryptable(secret)

      expect(encryptable.name).to eq('spec_secret')
      expect(encryptable.ose_secret).to eq(secret_yaml)
      expect(encryptable.type).to eq('ose_secret')
    end
  end
end
