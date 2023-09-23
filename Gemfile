source 'https://rubygems.org'

gemspec

gem 'faraday', '~> 1.9'
gem 'activesupport', '~> 3.2'
gem 'ffi', '~> 1.15.5'
gem "google-apis-analytics_v3"
gem 'mail', '2.6.6'
gem 'minitest', '< 5.0'
gem 'multi_json'
gem 'oj', '~> 2.0'
gem 'parseconfig'
gem 'pony'
gem 'pry'
gem 'rake'
gem 'redis'
gem 'rest-client'
gem 'sys-proctable'

# Monitoring
gem 'cube-ruby', require: 'cube'

gem 'goo', git: 'https://github.com/ontoportal-lirmm/goo.git', branch: 'ecoportal'
gem 'sparql-client', github: 'ontoportal-lirmm/sparql-client', branch: 'master'
gem 'ontologies_linked_data', git: 'https://github.com/lifewatch-eric/ontologies_linked_data.git', branch: 'master'
gem 'ncbo_annotator', github: 'ontoportal-lirmm/ncbo_annotator', branch: 'master'

group :development do
  # bcrypt_pbkdf and ed35519 is required for capistrano deployments when using ed25519 keys; see https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false
end


# Testing
group :test do
  gem 'email_spec'
  gem 'simplecov'
  gem 'simplecov-cobertura' # for codecov.io
  gem 'test-unit-minitest'
end

gem "binding_of_caller", "~> 1.0"
