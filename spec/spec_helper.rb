# frozen_string_literal: true

require_relative '../lib/errors'
require_relative '../lib/adapters/cry_adapter'
require_relative '../lib/adapters/ose_adapter'
require_relative '../lib/adapters/session_adapter'
require_relative '../lib/models/account'
require_relative '../lib/models/ose_secret'

require 'commander'
require 'commander/methods'

include Commander::Methods

def new_command_runner(*args, &block)
  require 'pry'; binding.pry unless $pstop
  Commander::Runner.instance_variable_set :"@singleton", Commander::Runner.new(args)
  program :name, 'test'
  program :version, '1.2.3'
  program :description, 'something'
  Commander::Runner.instance
end

RSpec.configure do |rspec|

end
