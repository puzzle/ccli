# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'psych'

describe OSEAdapter do
  subject { described_class.new }

  context 'fetch_secret' do
    it 'fetches secret and returns it as hash' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(3).times.and_return(cmd)

      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:twice).and_return(true)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(positive_result)

      secret_yaml = {
        type: 'Opaque',
        data: {
          token: 'very secret token'
        },
        metadata: {
          name: 'spec_secret'
        }
      }.to_yaml

      expect(cmd).to receive(:run).with('oc get -o yaml secret spec_secret').and_return(secret_yaml)

      result = Psych.load(subject.fetch_secret('spec_secret'), symbolize_names: true)

      expect(result[:type]).to eq('Opaque')
      expect(result[:data][:token]).to eq('very secret token')
      expect(result[:metadata][:name]).to eq('spec_secret')
    end

    it 'raises error if oc not installed' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(:once).and_return(cmd)

      negative_result = double

      expect(negative_result).to receive(:success?).exactly(:once).and_return(false)

      expect(cmd).to receive(:run!).with('which oc').and_return(negative_result)

      expect do
        subject.fetch_secret('spec_secret')
      end.to raise_error(OpenshiftClientMissingError)
    end

    it 'raises error if oc not logged in' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(:twice).and_return(cmd)

      negative_result = double
      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:once).and_return(true)
      expect(negative_result).to receive(:success?).exactly(:once).and_return(false)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(negative_result)

      expect do
        subject.fetch_secret('spec_secret')
      end.to raise_error(OpenshiftClientNotLoggedInError)
    end

    it 'raises error if secret was not found' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(3).times.and_return(cmd)

      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:twice).and_return(true)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(positive_result)

      error_result = double

      expect(error_result).to receive(:exit_status).and_return(1)
      expect(error_result).to receive(:out).and_return('')
      expect(error_result).to receive(:err).and_return('')

      expect(cmd).to receive(:run)
                 .with('oc get -o yaml secret non_existing_secret')
                 .and_raise(TTY::Command::ExitError.new('oc get secret', error_result))

      expect do
        subject.fetch_secret('non_existing_secret')
      end.to raise_error(OpenshiftSecretNotFoundError)
    end
  end

  context 'fetch_all_secrets' do
    it 'fetches every secret inside the list' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(3).times.and_return(cmd)

      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:twice).and_return(true)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(positive_result)

      secrets = ['spec_secret1', 'spec_secret2']

      expect(cmd).to receive(:run).with('oc get secret -o custom-columns=NAME:metadata.name --no-headers=true').and_return(secrets)

      expect(subject).to receive(:fetch_secret).with('spec_secret1').exactly(:once)
      expect(subject).to receive(:fetch_secret).with('spec_secret2').exactly(:once)

      subject.fetch_all_secrets
    end
  end

  context 'insert_secret' do
    it 'inserts secret into ose project' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(4).times.and_return(cmd)

      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:twice).and_return(true)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(positive_result)
      yaml = { apiVersion: 'v1', data: { password: 'very-secret-password' }, metadata: { name: 'spec_secret' } }.to_yaml
      secret = OSESecret.new('spec_secret', yaml)

      expect(cmd).to receive(:run).with('oc delete -f /tmp/spec_secret.yml --ignore-not-found=true')
      expect(cmd).to receive(:run).with('oc create -f /tmp/spec_secret.yml')

      subject.insert_secret(secret)
    end

    it 'raises error if oc not installed' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(:once).and_return(cmd)

      negative_result = double

      expect(negative_result).to receive(:success?).exactly(:once).and_return(false)

      expect(cmd).to receive(:run!).with('which oc').and_return(negative_result)
      yaml = { apiVersion: 'v1', data: { password: 'very-secret-password' }, metadata: { name: 'spec_secret' } }.to_yaml
      secret = OSESecret.new('spec_secret', yaml)

      expect do
        subject.insert_secret(secret)
      end.to raise_error(OpenshiftClientMissingError)
    end

    it 'raises error if oc not logged in' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(:twice).and_return(cmd)

      negative_result = double
      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:once).and_return(true)
      expect(negative_result).to receive(:success?).exactly(:once).and_return(false)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc project').and_return(negative_result)
      yaml = { apiVersion: 'v1', data: { password: 'very-secret-password' }, metadata: { name: 'spec_secret' } }.to_yaml
      secret = OSESecret.new('spec_secret', yaml)

      expect do
        subject.insert_secret(secret)
      end.to raise_error(OpenshiftClientNotLoggedInError)
    end
  end
end
