require 'base64'
require 'json'
require 'net/http'
require 'uri'

module NcboCron
  module Models
    class OBOFoundrySync

      def run
        # Get a map of OBO ID spaces to BioPortal acronyms
        map = get_ids_to_acronyms_map

        onts = get_obofoundry_ontologies
        onts.reject! { |ont| ont.key?("is_obsolete") }
        missing_onts = []

        # Are any OBO Library ontologies missing from BioPortal?
        if onts.size != map.size
          onts.each do |ont|
            if not map.key?(ont["id"])
              missing_onts << ont
            end
          end
        end

        LinkedData::Utils::Notifications.obofoundry_sync(missing_onts)
      end

      # TODO: DRY up the code in the following two methods

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

        oauth_token = Base64.decode64(NcboCron.settings.git_repo_access_token)
        uri = URI.parse("https://api.github.com/graphql")
        req_options = { use_ssl: uri.scheme == "https" }
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "bearer #{oauth_token}"
        request.body = JSON.dump({"query" => query})
        
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        parsed = JSON.parse(response.body)
        text = parsed.dig("data", "repository", "object", "text")
        JSON.parse(text)
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

        oauth_token = Base64.decode64(NcboCron.settings.git_repo_access_token)
        uri = URI.parse("https://api.github.com/graphql")
        req_options = { use_ssl: uri.scheme == "https" }
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "bearer #{oauth_token}"
        request.body = JSON.dump({"query" => query})
        
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        parsed = JSON.parse(response.body)
        text = parsed.dig("data", "repository", "object", "text")
        ont_registry = JSON.parse(text)
        onts = ont_registry["ontologies"].to_a
        return onts
      end

    end
  end
end


