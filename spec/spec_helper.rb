# frozen_string_literal: true

require_relative '../lib/errors'
require_relative '../lib/adapters/cry_adapter'
require_relative '../lib/adapters/ose_adapter'
require_relative '../lib/adapters/session_adapter'
require_relative '../lib/models/account'
require_relative '../lib/models/ose_secret'

require 'commander'
require 'commander/methods'

RSpec.configure do |rspec|

end

def exit_error(msg)
  error_result = double

  expect(error_result).to receive(:exit_status).and_return(1)
  expect(error_result).to receive(:out).and_return('')
  expect(error_result).to receive(:err).and_return('')
  TTY::Command::ExitError.new(msg, error_result)
end

