require 'base64'
require 'json'
require 'net/http'
require 'uri'

module NcboCron
  module Models
    class OBOFoundrySync

      def initialize
        @logger = Logger.new(STDOUT)
        @oauth_token = Base64.decode64(NcboCron.settings.git_repo_access_token)
        @graphql_uri = URI.parse("https://api.github.com/graphql")
        @request_options = { use_ssl: @graphql_uri.scheme == "https" }
      end

      def run
        # Get a map of OBO ID spaces to BioPortal acronyms
        map = get_ids_to_acronyms_map

        onts = get_obofoundry_ontologies
        @logger.info("Found #{onts.size} OBO Library ontologies")

        # Are any OBO Library ontologies missing from BioPortal?
        missing_onts = []
        active_onts = onts.reject { |ont| ont.key?("is_obsolete") }
        active_onts.each do |ont|
          if not map.key?(ont["id"])
            missing_onts << ont
            @logger.info("Missing OBO Library ontology: #{ont['title']} (#{ont['id']})")
          end
        end

        # Have any of the OBO Library ontologies that BioPortal hosts become obsolete?
        obsolete_onts = []
        ids = active_onts.map{ |ont| ont["id"] }
        obsolete_ids = map.keys - ids
        obsolete_ids.each do |id|
          ont = onts.find{ |ont| ont["id"] == id }
          @logger.info("Deprecated OBO Library ontology: #{ont['title']} (#{ont['id']})")
          obsolete_onts << ont
        end        

        LinkedData::Utils::Notifications.obofoundry_sync(missing_onts, obsolete_onts)
      end

      def get_ids_to_acronyms_map
        query = "query { 
                  repository(name: \"ncbo.github.io\", owner: \"ncbo\") {
                    object(expression: \"master:oboids_to_bpacronyms.json\") {
                      ... on Blob {
                        text
                      }
                    }
                  }
                }"

        response = issue_request(query)
        JSON.parse(response)
      end

      def get_obofoundry_ontologies
        query = "query { 
                  repository(name: \"OBOFoundry.github.io\", owner: \"OBOFoundry\") {
                    object(expression: \"master:registry/ontologies.jsonld\") {
                      ... on Blob {
                        text
                      }
                    }
                  }
                }"

        response = issue_request(query)
        ont_registry = JSON.parse(response)
        ont_registry["ontologies"].to_a
      end

      def issue_request(query)
        request = Net::HTTP::Post.new(@graphql_uri)
        request["Authorization"] = "bearer #{@oauth_token}"
        request.body = JSON.dump({"query" => query})
        
        response = Net::HTTP.start(@graphql_uri.hostname, @graphql_uri.port, @request_options) do |http|
          http.request(request)
        end

        parsed = JSON.parse(response.body)
        parsed.dig("data", "repository", "object", "text")
      end

    end
  end
end
