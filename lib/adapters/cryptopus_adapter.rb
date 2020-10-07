# frozen_string_literal: true

require 'singleton'
require 'net/http'
require 'json'
require 'base64'

class CryptopusAdapter

  def root_url
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

  def save_secret(secret)
    secret_account = secret.to_account
    secret_account.folder = session_adapter.selected_folder.id

    begin
      persisted_secret = find_account_by_name(secret.name)
      patch("accounts/#{persisted_secret.id}", secret_account.to_json)
    rescue CryptopusAccountNotFoundError
      post('accounts', secret_account.to_json)
    end
  end

  def find_account_by_name(name)
    secret_account = Account.find_by_name_and_folder_id(name, session_adapter.selected_folder.id)

    raise CryptopusAccountNotFoundError unless secret_account

    secret_account
  end

  private

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
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    raise UnauthorizedError if response.is_a?(Net::HTTPUnauthorized)
    raise ForbiddenError if response.is_a?(Net::HTTPForbidden)

    response.body
  end
end
