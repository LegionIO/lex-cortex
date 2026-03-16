# frozen_string_literal: true

require_relative 'lib/legion/extensions/cortex/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cortex'
  spec.version       = Legion::Extensions::Cortex::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cortex'
  spec.description   = 'Cognitive wiring layer for LegionIO agentic architecture'
  spec.homepage      = 'https://github.com/LegionIO/lex-cortex'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-cortex'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-cortex'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-cortex'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-cortex/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
