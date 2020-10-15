# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'psych'

describe ClusterSecretAdapter do
  subject { described_class.new }

  before do
    allow(subject).to receive(:client).and_return('oc')
    allow(subject).to receive(:client_missing_error).and_return(OpenshiftClientMissingError)
    allow(subject).to receive(:client_not_logged_in_error).and_return(OpenshiftClientNotLoggedInError)
  end

  context 'fetch_secret' do
    it 'fetches secret and returns it as hash' do
      cmd = double

      expect(subject).to receive(:cmd).exactly(3).times.and_return(cmd)

      positive_result = double

      expect(positive_result).to receive(:success?).exactly(:twice).and_return(true)

      expect(cmd).to receive(:run!).with('which oc').and_return(positive_result)
      expect(cmd).to receive(:run!).with('oc get secret').and_return(positive_result)

      secret_yaml = {
        'items' => [{
          type: 'Opaque',
          data: {
            token: 'very secret token'
          },
          metadata: {
            name: 'spec_secret'
          }
        }]
      }.to_yaml

      expect(cmd).to receive(:run).with("oc get -o yaml secret --field-selector='metadata.name=spec_secret' " \
                                        '-l cryptopus-sync=true').and_return([secret_yaml])

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
      expect(cmd).to receive(:run!).with('oc get secret').and_return(negative_result)

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
      expect(cmd).to receive(:run!).with('oc get secret').and_return(positive_result)

      expect(cmd).to receive(:run)
        .with("oc get -o yaml secret --field-selector='metadata.name=non_existing_secret' -l cryptopus-sync=true")
                 .and_raise(exit_error('oc get secret'))

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
      expect(cmd).to receive(:run!).with('oc get secret').and_return(positive_result)

      secrets = { 
        'items' => ['spec_secret1', 'spec_secret2']
      }.to_yaml

      expect(cmd).to receive(:run).with("oc get secret -o yaml -l cryptopus-sync=true").and_return(secrets)

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
      expect(cmd).to receive(:run!).with('oc get secret').and_return(positive_result)
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
      expect(cmd).to receive(:run!).with('oc get secret').and_return(negative_result)
      yaml = { apiVersion: 'v1', data: { password: 'very-secret-password' }, metadata: { name: 'spec_secret' } }.to_yaml
      secret = OSESecret.new('spec_secret', yaml)

      expect do
        subject.insert_secret(secret)
      end.to raise_error(OpenshiftClientNotLoggedInError)
    end
  end
end
