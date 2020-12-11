# frozen_string_literal: true

class FileSystemAdapter

  SECRETS_FOLDER_NAME = 'ose-secrets'

  def initialize(path: './')
    @path = path
  end

  def fetch_secrets
    raise NotSecretsDirectoryError unless secrets_path?

    secrets = []
    secrets_directory.each_child do |secret_dir|
      next unless Dir.exists?("#{path}/#{secret_dir}")

      secrets << extract_secret(secret_dir)
    end
    secrets
  end

  private

  attr_reader :path

  def extract_secret(secret_dir)
    data = {}
    Dir.new(secret_dir).each_child do |value_file|
      File.open("#{path}/#{secret_dir}/#{value_file}", 'r') do |file|
        data[File.basename(value_file.path, '.*')] = file.read.strip
      end
    end

    yaml = { apiVersion: 'v1', data: data, metadata: { name: secret_dir } }.to_yaml

    OseSecret.new(secret_dir, yaml)
  end

  def secrets_path?
    Dir.exists?(path) && File.basename(secrets_directory.name).include?(SECRETS_FOLDER_NAME)
  end

  def secrets_directory
    Dir.new(path)
  end
end
