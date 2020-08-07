# frozen_string_literal: true

require 'singleton'

class CryAdapter
  include Singleton

  def root_url
  end

  def get(path, id)
  end

  def post(path, body)
  end

  def patch(path, id, body)
  end
end
