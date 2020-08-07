# frozen_string_literal: true

require 'rubygems'
require 'commander'

class CLI
  include Commander::Methods

  def run
    program :name, 'ccli - cryptopus ccli'
    program :version, '0.1.0'
    program :description, 'CLI tool to manage openshift secrets'

    run!
  end
end

CLI.new.run if $PROGRAM_NAME == __FILE__
