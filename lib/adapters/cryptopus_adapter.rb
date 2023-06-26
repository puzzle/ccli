# frozen_string_literal: true

require 'singleton'
require 'net/http'
require 'json'
require 'base64'

class CryptopusAdapter

  def root_url
    raise SessionMissingError unless session_adapter.session_data[:url]

    @root_url ||= "#{session_adapter.session_data[:url]}/api"
  end

  def get(path)
    uri = URI("#{root_url}/#{path}")
    request = new_request(:get, uri)
    send_request(request, uri)
  end

  def post(path, body)
    uri = URI("#{root_url}/#{path}")
    request = new_request(:post, uri)
    request.body = body
    send_request(request, uri)
  end

  def patch(path, body)
    uri = URI("#{root_url}/#{path}")
    request = new_request(:patch, uri)
    request.body = body
    send_request(request, uri)
  end

  def find_encryptable_by_name(name)
    secret_encryptable = Encryptable.find_by_name_and_folder_id(name, session_adapter.selected_folder.id)

    raise CryptopusEncryptableNotFoundError unless secret_encryptable

    secret_encryptable
  end

  def renewed_auth_token
    json = get("api_users/#{current_user_id}/token")
    JSON.parse(json)['token']
  end

  private

  def current_user_id
    users = JSON.parse(get('api_users'), symbolize_names: true)
    users[:data].find do |user|
      user[:attributes][:username] == session_adapter.session_data[:username]
    end[:id]
  end

  def session_adapter
    @session_adapter ||= SessionAdapter.new
  end

  def header_token
    Base64.strict_encode64(session_adapter.session_data[:token] || '')
  end

  def new_request(verb, uri)
    request = Object.const_get("Net::HTTP::#{verb.capitalize}").new(uri)
    request['Authorization-User'] = session_adapter.session_data[:username]
    request['Authorization-Password'] = header_token
    if [:post, :patch].include? verb
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/vnd.api+json'
    end
    request
  end

  def send_request(request, uri)
    is_ssl_connection = uri.port == 443
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: is_ssl_connection) do |http|
      http.request(request)
    end
    raise UnauthorizedError if response.is_a?(Net::HTTPUnauthorized)
    raise ForbiddenError if response.is_a?(Net::HTTPForbidden)

    response.body
  end
end
