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
        onts.reject! { |ont| ont.key?("is_obsolete") }
        @logger.info("Found #{onts.size} non-obsolete OBO Foundry ontologies")
        missing_onts = []

        # Are any OBO Library ontologies missing from BioPortal?
        if onts.size != map.size
          onts.each do |ont|
            if not map.key?(ont["id"])
              missing_onts << ont
              @logger.info("OBO Foundry ontology missing from BioPortal: #{ont['title']} (#{ont['id']})")
            end
          end
        end

        LinkedData::Utils::Notifications.obofoundry_sync(missing_onts)
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
