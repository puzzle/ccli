# frozen_string_literal: true

require 'singleton'

class SessionAdapter
  include Singleton

  def update_session(token, url)
  end

  def update_folder(id)
  end

  def session_data
  end

  def clear_session
  end

  def folder_selected?
  end

  private

  def session_file
  end

  def extracted_token(token)
  end
end
