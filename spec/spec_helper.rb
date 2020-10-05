# frozen_string_literal: true

Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].sort.each { |file| require file }

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

