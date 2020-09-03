# frozen_string_literal: true

require 'singleton'
require 'net/http'
require 'json'
require 'base64'

class CryAdapter

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

  def save_secrets(secrets)
    secrets.each do |secret|
      secret_account = secret.to_account
      secret_account.folder = session_adapter.selected_folder_id

      persisted_secret = persisted_secret_account(secret.name)
      if persisted_secret
        patch("accounts/#{persisted_secret.id}", secret_account.to_json)
      else
        post('accounts', secret_account.to_json)
      end
    end
  end

  def find_secret_account_by_name(name)
    secret_account = persisted_secret_account(name)

    raise CryptopusAccountNotFoundError unless secret_account

    get("accounts/#{secret_account.id}")
  end

  private

  def persisted_secret_account(secret_name)
    folder_accounts.select do |a|
      a.accountname == secret_name
    end.first
  end

  def folder_accounts
    json = get("folders/#{session_adapter.selected_folder_id}")
    included = json[:included] || []
    @folder_accounts ||= included.map do |record|
      Account.from_json(record) if record[:type] == 'accounts'
    end.compact
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
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    raise UnauthorizedError if response.is_a?(Net::HTTPUnauthorized)
    raise ForbiddenError if response.is_a?(Net::HTTPForbidden)

    JSON.parse(response.body, symbolize_names: true)
  end
end
