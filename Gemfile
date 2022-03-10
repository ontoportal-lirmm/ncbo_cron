source 'https://rubygems.org'

gemspec

gem 'faraday', '~> 1.9'
gem 'ffi'
gem 'google-api-client', '~> 0.10'
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

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', github: 'ncbo/goo', branch: 'develop'
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: 'develop'
# switch back to develop branch after ontologies_linked_data is released
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'remove_ncbo_resource_index'
#gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'develop'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'develop'

group :test do
  gem 'email_spec'
  gem 'test-unit-minitest'
end

