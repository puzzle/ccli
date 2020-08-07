# frozen_string_literal: true

require 'singleton'

class OSEAdapter
  include Singleton

  def retrieve_secret(name)
  end

  def retrieve_all_secrets
  end

  def insert_secret(yaml)
  end
end
