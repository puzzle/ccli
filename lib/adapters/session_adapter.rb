# frozen_string_literal: true

require 'base64'
require 'singleton'
require 'yaml'
require 'fileutils'

class SessionAdapter
  include Singleton

  FILE_LOCATION = '~/.ccli/session'

  def update_session(token, url)
    FileUtils.mkdir_p ccli_directory_path unless ccli_directory_exists?
    File.open(session_file_path, 'w') do |file|
      config = extracted_token(token)
      config[:url] = url
      file.write config.to_yaml
    end
  end

  def update_folder(id)
  end

  def session_data
  end

  def clear_session
    return unless ccli_directory_exists?

    FileUtils.rm_r(ccli_directory_path)
  end

  def folder_selected?
  end

  private

  def extracted_token(token)
    return {} unless token

    decoded_token = Base64.decode64(token)
    attrs = decoded_token.split(';')
    {
      username: attrs[0],
      token: attrs[1]
    }
  end

  def session_file_path
    File.expand_path(FILE_LOCATION)
  end

  def ccli_directory_path
    File.dirname(session_file_path)
  end

  def session_file_exists?
    File.exist?(session_file_path)
  end

  def ccli_directory_exists?
    Dir.exist?(ccli_directory_path)
  end
end
