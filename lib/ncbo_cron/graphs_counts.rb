#!/usr/bin/env ruby
require 'logger'
require 'optparse'

module NcboCron
  module GraphsCounts
    SUBMISSION_DATA_GRAPH = 'http://data\.bioontology\.org/ontologies/[^/]+/submissions/\d+'

    def run(logger, file_path)
      logger.info('Start generating graphs counts')
      logger.info('Fetch ontologies data graphs')
      @all_ontologies = LinkedData::Models::Ontology.all
      @all_subs = all_ontologies.map{|x| x.latest_submission(status: any)}

      logger.info('Fetch all graphs URIs')
      graphs = graphs_list
      result = {}
      graphs.each do |graph|
        logger.info("Calculate the triple count of #{graph}")
        result[graph] = [graph_count_triples(graph), zombie_graph?(graph)]
      end

      logger.info("Save the result in file #{file_path}")
      save_result_in_file(file_path, result)
      logger.info('Finish generating graphs counts')
    end


    private
    def save_result_in_file(file_path, results)
      File.open(file_path, 'w') do |f|
        f.write(results.to_json)
      end
    end

    def zombie_graph?(graph)
      regex = Regexp.new(SUBMISSION_DATA_GRAPH)
      return false unless regex.match?(url)

      !@all_subs.find{ |x| x.id.to_s == graph.to_s }.present?
    end

    def graph_count_triples(graph)
      query = <<-eos
            SELECT (COUNT(?s) as ?count) WHERE {
            GRAPH #{graph.to_ntriples} {
              ?s ?p ?v
            }}
          eos
      rs = Goo.sparql_query_client.query(query)
      count = 0
      rs.each do |sol|
        count = sol[:count].object
      end
      count
    end

    def graphs_list
      query = <<-eos
            SELECT DISTINCT ?g WHERE {
            GRAPH ?g {
              ?s ?p ?v
            }}
      eos
      rs = Goo.sparql_query_client.query(query)
      rs.solutions.map { |x| x[:g].to_s }
    end
  end
end
