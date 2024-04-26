source 'https://rubygems.org'

gemspec

gem 'ffi'

# This is needed temporarily to pull the Google Universal Analytics (UA)
# data and store it in a file. See (bin/import_google_ua_analytics_data)
# The ability to pull this data from Google will cease on July 1, 2024
gem "google-apis-analytics_v3"

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
gem 'request_store'
gem 'parallel'
gem 'json-ld'

# Monitoring
gem 'cube-ruby', require: 'cube'

gem 'goo', github: 'ontoportal-lirmm/goo', branch: 'development'
gem 'sparql-client', github: 'ontoportal-lirmm/sparql-client', branch: 'master'
gem 'ontologies_linked_data', github: 'ontoportal-lirmm/ontologies_linked_data', branch: 'development'
gem 'ncbo_annotator', github: 'ontoportal-lirmm/ncbo_annotator', branch: 'development'
# Testing
group :test do
  gem 'email_spec'
  gem 'minitest', '< 5.0'
  gem 'simplecov'
  gem 'simplecov-cobertura' # for codecov.io
  gem 'test-unit-minitest'
end

gem "binding_of_caller", "~> 1.0"
