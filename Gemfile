source 'https://rubygems.org'

gemspec

gem 'ffi'
gem 'google-analytics-data'
gem 'mail', '2.6.6'
gem 'multi_json'
gem 'oj', '~> 3.0'
gem 'parseconfig'
gem 'pony'
gem 'pry'
gem 'rake'
gem 'redis'
gem 'rest-client'
gem 'sys-proctable'

# Monitoring
gem 'cube-ruby', require: 'cube'

# NCBO
gem 'goo', github: 'ncbo/goo', branch: 'master'
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: 'master'
gem 'ncbo_resource_index', github: 'ncbo/resource_index'
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'master'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'master'

group :test do
  gem 'email_spec'
  gem 'minitest', '< 5.0'
  gem 'simplecov'
  gem 'simplecov-cobertura' # for codecov.io
  gem 'test-unit-minitest'
end
