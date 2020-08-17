# frozen_string_literal: true

require 'singleton'
require 'net/http'
require 'json'
require 'base64'

class CryAdapter

  def root_url
    @root_url ||= "#{session_adapter.session_data[:url]}/api"
  end

  def get(path, id)
    uri = URI("#{root_url}/#{path}/#{id}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization-User'] = session_adapter.session_data[:username]
    request['Authorization-Password'] = header_token
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    raise UnauthorizedError if response.is_a?(Net::HTTPUnauthorized)

    JSON.parse(response.body)
  end

  def post(path, body)
  end

  def patch(path, id, body)
  end

  private

  def session_adapter
    @session_adapter ||= SessionAdapter.new
  end

  def header_token
    Base64.strict_encode64(session_adapter.session_data[:token] || '')
  end
end
