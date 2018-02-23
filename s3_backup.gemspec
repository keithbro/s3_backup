lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 's3_backup/version'

Gem::Specification.new do |s|
  s.name          = 's3_backup'
  s.version       = S3Backup::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Tom Floc'h"]
  s.email         = ['thomas.floch@gmail.com']
  s.homepage      = 'https://github.com/arkes/s3_backup'
  s.summary       = 'Postgres, redis backup and restore'
  s.description   = 'Postgres, redis backup and restore'

  s.license       = 'MIT'

  s.files         = Dir.glob('{lib,spec}/**/*') + %w[README.md Rakefile Gemfile .rspec]

  s.add_dependency 'aws-sdk-s3', '~> 1.8'
  s.add_dependency 'faker', '>= 1.4'
  s.add_dependency 'ruby-progressbar', '~> 1.8'
  s.add_dependency 'mime-types', '>= 1.25'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 0.49'
end
