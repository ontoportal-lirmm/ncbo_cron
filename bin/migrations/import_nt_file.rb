require 'bundler/setup'
require 'pry'
require 'benchmark'
require 'ncbo_annotator'
require 'ncbo_cron'
require 'ontologies_linked_data'

file_path = ARGV[0]
graph = ARGV[1]
profile = ARGV[2]

if file_path.nil? && graph.nil?
  puts "Error: Missing arguments. Please provide the file path and the graph name."
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
puts "Start importing file: #{file_path} to graph: #{graph} using profile: #{ENV['GOO_BACKEND_NAME']}"
puts "Delete graph: #{graph}"
time = Benchmark.realtime do
  Goo.sparql_data_client.delete_graph(graph)
end
puts 'Time to delete graph: ' + format("%.4f", time.to_s) + 's'

time = Benchmark.realtime do
   Goo.sparql_data_client.append_triples_no_bnodes(graph, file_path, nil)
end
puts 'Time to append triples: ' + format("%.4f", time) + 's'

puts "Count triples in graph: #{graph}"
count = 0
time = Benchmark.realtime do
   count = Goo.sparql_query_client.query("SELECT (COUNT(?s) as ?count) FROM <#{graph}> WHERE { ?s ?p ?o }")
end
puts 'Time to count triples: ' + format("%.4f", time) + 's with total count: ' + count.to_s
