# require 'bundler/setup'
require 'pry'
require 'benchmark'
require 'ncbo_annotator'
require 'ncbo_cron'
require 'ontologies_linked_data'

graph = ARGV[1]
profile = ARGV[2]

if graph.nil?
  puts "Error: Missing arguments. Please provide the graph name."
  exit(1)
end

case profile
when 'ag'
  # AllegroGraph backend
  ENV['GOO_BACKEND_NAME'] = 'allegrograph'
  ENV['GOO_PORT'] = '10035'
  ENV['GOO_PATH_QUERY'] = '/repositories/ontoportal_test'
  ENV['GOO_PATH_DATA'] = '/repositories/ontoportal_test/statements'
  ENV['GOO_PATH_UPDATE'] = '/repositories/ontoportal_test/statements'
  ENV['COMPOSE_PROFILES'] = 'ag'

when 'fs'
  # 4store backend
  ENV['GOO_PORT'] = '9000'
  ENV['COMPOSE_PROFILES'] = 'fs'

when 'vo'
  # Virtuoso backend
  ENV['GOO_BACKEND_NAME'] = 'virtuoso'
  ENV['GOO_PORT'] = '8890'
  ENV['GOO_PATH_QUERY'] = '/sparql'
  ENV['GOO_PATH_DATA'] = '/sparql'
  ENV['GOO_PATH_UPDATE'] = '/sparql'
  ENV['COMPOSE_PROFILES'] = 'vo'

when 'gb'
  # Graphdb backend
  ENV['GOO_BACKEND_NAME'] = 'graphdb'
  ENV['GOO_PORT'] = '7200'
  ENV['GOO_PATH_QUERY'] = '/repositories/ontoportal'
  ENV['GOO_PATH_DATA'] = '/repositories/ontoportal/statements'
  ENV['GOO_PATH_UPDATE'] = '/repositories/ontoportal/statements'

else
  puts "Will import to default config set in config/config.rb"
end

require_relative '../../config/config'
count = 0
time = Benchmark.realtime do
  rs = Goo.sparql_query_client.query("SELECT (COUNT(?s) as ?count) FROM <#{graph_uri}> WHERE { ?s ?p ?o }")
  rs = rs.solutions.first
  count = rs[:count].to_i  if rs
end

puts 'Imported triples in ' + format("%.4f", time) + 's with total count: ' + count.to_s
