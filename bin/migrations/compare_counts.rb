require 'open3'
require 'net/http'
require 'json'
require 'cgi'
require 'csv'
require 'pry'
require 'bundler/setup'
require 'benchmark'
require 'ncbo_annotator'
require 'ncbo_cron'
require 'ontologies_linked_data'

PROCESSED_DIR = ARGV[0] || './processed_files'
profile = ARGV[1]


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
# Set your Virtuoso SPARQL endpoint, user credentials, and the directory where the .n3 files are located
OUTPUT_CSV = './graph_comparison.csv'

def get_all_graphs_counts
  graphs = []
  time = Benchmark.realtime do
    rs = Goo.sparql_query_client.query("SELECT DISTINCT ?graph (COUNT(?s) as ?triplesCount) WHERE { GRAPH ?graph { ?s ?p ?o } } GROUP BY ?graph")
    rs.each do |solution|
      graphs << solution
    end
  end
  puts 'Found ' + graphs.length.to_s + ' graphs in ' + format("%.4f", time) + 's'

  counts = {}
  graphs.each do |graph|
    counts[graph['graph'].to_s] = graph['triplesCount'].to_i
  end
  counts
end

# Count the number of lines in a file (excluding the first metadata line)
def count_file_lines(file_path)
  File.read(file_path).each_line.count
end

def build_graphs_file_hash(folder_path = PROCESSED_DIR)
  # Ensure the folder path exists
  unless Dir.exist?(folder_path)
    puts "Folder does not exist: #{folder_path}"
    return
  end

  graphs = {}
  # Loop through each file in the folder
  Dir.foreach(folder_path) do |filename|
    # Skip directories and only process files ending with .graph and starting with the specific string
    if filename.end_with?('.graph')
      file_path = File.join(folder_path, filename)
      line = File.open(file_path, "r").readlines.first
      graphs[line.strip] = filename.to_s.gsub('.graph','')
    end
  end
  graphs
end

# Compare graph counts with file lines and output to CSV
def compare_graphs_with_files(graph_triples)
  CSV.open(OUTPUT_CSV, 'w') do |csv|
    # Write CSV headers
    csv << ["Graph URI", "Triples in Graph", "Lines in File (excluding metadata)", "Match"]
    graphs_files = build_graphs_file_hash
    graph_triples.each do |graph, count|
      graph_uri = graph
      triples_count = count
      graph_filename = graphs_files[graph_uri]

      next csv << [graph_uri, triples_count, "Graph not found", "N/A"] unless graph_filename
      
      # Construct the expected file name based on the graph URI
      file_name = "#{PROCESSED_DIR}/#{graph_filename}"
      
      # puts "count lines of the file #{file_name} for the graph #{graph_uri}"
      if File.exist?(file_name)
        file_lines_count = count_file_lines(file_name)

        # Check if the counts match
        match_status = triples_count == file_lines_count ? "Yes" : "No"

        # Output the result to CSV
        csv << [graph_uri, triples_count, file_lines_count, match_status]
      else
        # If the file doesn't exist, indicate it in the CSV
        csv << [graph_uri, triples_count, "File not found", "N/A"]
      end
    end
  end

  puts "Comparison complete. Results saved to #{OUTPUT_CSV}"
end

# Main execution

Goo.sparql_query_client.cache.redis_cache.flushdb
puts "Redis cache flushed"

puts "Comparing graph triple counts with file lines and exporting to CSV..."
graph_triples = get_all_graphs_counts
compare_graphs_with_files(graph_triples)

count = 0
attr_ontology = []
time = Benchmark.realtime do
  attr_ontology = LinkedData::Models::Ontology.attributes(:all)
  count = LinkedData::Models::Ontology.where.include(attr_ontology).all.count
end
puts "Ontologies count: #{count} with display=all in #{format("%.4f", time)}s"
count = 0
time = Benchmark.realtime do
  count = LinkedData::Models::OntologySubmission.where.all.count
end
puts "Submissions count: #{count} with no display in #{format("%.4f", time)}s"

count = 0
time = Benchmark.realtime do
  attr = LinkedData::Models::OntologySubmission.attributes(:all)
  attr << {ontology: attr_ontology}
  count = LinkedData::Models::OntologySubmission.where.include(attr).all.count
end
puts "Submissions count: #{count} with display=all in #{format("%.4f", time)}s"

count = 0
time = Benchmark.realtime do
  attr = LinkedData::Models::Agent.attributes(:all)
  count = LinkedData::Models::Agent.where.include(attr).all.count
end
puts "Agent count: #{count} with display=all in #{format("%.4f", time)}s"

count = 0
time = Benchmark.realtime do
  attr = LinkedData::Models::MappingCount.attributes(:all)
  count = LinkedData::Models::MappingCount.where.include(attr).all.count
end
puts "MappingsCount count: #{count} with display=all in #{format("%.4f", time)}s"

count = 0
time = Benchmark.realtime do
  count += LinkedData::Models::RestBackupMapping.where.all.count
end
puts "RestMappings count: #{count} with no display in #{format("%.4f", time)}s"

count = 0
time = Benchmark.realtime do
  attr = LinkedData::Models::RestBackupMapping.attributes(:all) + LinkedData::Models::MappingProcess.attributes(:all)
  count += LinkedData::Models::RestBackupMapping.where.include(attr).all.count
end
puts "RestMappings count: #{count} with display=all in #{format("%.4f", time)}s"
