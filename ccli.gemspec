# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = 'ccli'
  s.description   = <<-EOF
    CCLI is the Cryptopus Command Line Interface. It allows to fetch account data and list teams from Cryptopus.
    One of the main functionality is backing up secrets from cluster services (currently: openshift, kubernetes)
    to Cryptopus and restoring them as well.
  EOF
  s.version       = '1.0.1'
  s.summary       = 'Command line client for the opensource password manager Cryptopus'
  s.license       = 'MIT'
  s.homepage      = 'https://github.com/puzzle/ccli'
  s.authors       = ['Nils Rauch']
  s.email         = 'rauch@puzzle.ch'
  s.require_paths = ['lib']
  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{(^(test|spec|features)/)})
  end
  s.bindir        = 'bin'
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.required_ruby_version = Gem::Requirement.new('>= 2.0')
  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/puzzle/ccli/issues",
    "changelog_uri"     => "https://github.com/puzzle/ccli/blob/master/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/puzzle/ccli"
  }

  s.add_runtime_dependency 'commander', '~> 4.5', '>= 4.5.2'
  s.add_runtime_dependency 'tty-command'
  s.add_runtime_dependency 'tty-exit'
  s.add_runtime_dependency 'tty-logger'

end
