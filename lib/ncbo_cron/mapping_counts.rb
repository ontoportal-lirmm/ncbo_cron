
module NcboCron
  module Models
  
    class MappingCounts
      def initialize(logger)
        @logger = logger
      end
  
      def run
        LinkedData::Mappings.create_mapping_counts(@logger)
      end
    end
  
  end
end

# require 'ontologies_linked_data'
# require 'goo'
# require 'ncbo_annotator'
# require 'ncbo_cron/config'
# require_relative '../../config/config'
#
# log_path = File.join("logs", "mapping-counts.log")
# logger = Logger.new(log_path)
# NcboCron::Models::MappingCounts.new(logger).run

# bundle exec ruby ./lib/ncbo_cron/mapping_counts.rb