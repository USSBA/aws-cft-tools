# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_cft_tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'aws-cft-tools'
  spec.version       = AwsCftTools::VERSION
  spec.authors       = ['Small Business Administration']
  spec.email         = ['help@certify.sba.gov']

  spec.summary       = 'Tools for managing CloudFormation Templates'
  spec.description   = 'Tools for managing a cloud deployment in AWS with state held in AWS.'
  spec.homepage      = 'https://github.com/USSBA/aws-cft-tools'
  spec.license       = 'Apache2'

  spec.required_ruby_version = '>= 2.4.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against ' \
  #     'public gem pushes.'
  # end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2.9.22'
  spec.add_dependency 'clamp', '~> 1.1.2'
  spec.add_dependency 'cloudformation-ruby-dsl', '~> 1.4.6'
  spec.add_dependency 'diffy', '~> 3.2.0'
  spec.add_dependency 'table_print', '~> 1.5.6'

  spec.add_development_dependency 'asciidoctor', '~> 1.5.6'
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.49.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.15.1'
  spec.add_development_dependency 'rubycritic'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock', '~> 3.0.1'
  spec.add_development_dependency 'yard', '~> 0.9.9'
end
