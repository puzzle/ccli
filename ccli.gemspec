# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = 'ccli'
  s.version       = '0.1.0'
  s.summary       = 'Command line client for the opensource password manager Cryptopus'
  s.authors       = ['Nils Rauch']
  s.email         = 'rauch@puzzle.ch'
  s.require_paths = ['lib']
  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{(^(test|spec|features)/)})
  end
  s.bindir        = 'bin'
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.required_ruby_version = Gem::Requirement.new('>= 2.0')

  s.add_runtime_dependency 'commander', '~> 4.5', '>= 4.5.2'
  s.add_runtime_dependency 'tty-command'
  s.add_runtime_dependency 'tty-exit'
end
