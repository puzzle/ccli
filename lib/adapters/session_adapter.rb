# frozen_string_literal: true

require 'base64'
require 'singleton'
require 'yaml'
require 'fileutils'
require 'psych'

class SessionAdapter

  FILE_LOCATION = '~/.ccli/session'

  def update_session(session)
    session.merge!(session_data) { |_key, input| input } if session_file_exists?

    FileUtils.mkdir_p ccli_directory_path unless ccli_directory_exists?
    File.open(session_file_path, 'w') do |file|
      session.merge!(extracted_token(session[:encoded_token])) { |_key, _v1, v2| v2 }
      session.delete(:encoded_token)
      file.write session.to_yaml
    end
  end

  def session_data
    raise SessionMissingError unless session_file_exists?

    @session_data ||= Psych.load_file(session_file_path)
  end

  def clear_session
    return unless ccli_directory_exists?

    FileUtils.rm_r(ccli_directory_path)
  end

  def selected_folder
    @selected_folder ||= Folder.find(selected_folder_id)
  end

  private

  def selected_folder_id
    raise NoFolderSelectedError if session_data[:folder].nil?

    session_data[:folder]
  end

  def extracted_token(token)
    return {} unless token

    decoded_token = Base64.decode64(token)
    attrs = decoded_token.split(':')
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
