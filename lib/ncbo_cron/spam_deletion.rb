require 'logger'
require 'base64'

module NcboCron
  module Models

    class SpamDeletion
      OWNER = "ncbo"
      REPO = "documentation"
      REPO_PATH = "spam/spam_users.txt"
      FULL_FILE_PATH = "https://api.github.com/repos/#{OWNER}/#{REPO}/contents/#{REPO_PATH}"

      def initialize(logger=nil)
        @logger = nil

        if logger.nil?
          log_file = File.new(NcboCron.settings.log_path, "a")
          log_path = File.dirname(File.absolute_path(log_file))
          log_filename_no_ext = File.basename(log_file, ".*")
          spam_deletion_log_path = File.join(log_path, "#{log_filename_no_ext}-spam-deletion.log")
          @logger = Logger.new(spam_deletion_log_path)
        else
          @logger = logger
        end
      end

      def run
        auth_token = NcboCron.settings.git_repo_access_token
        res = `curl --header 'Authorization: token #{auth_token}' --header 'Accept: application/vnd.github.v3.raw' --location #{FULL_FILE_PATH}`

        begin
          error_json = JSON.parse(res)
          msg = "\nError while fetching the SPAM user list from #{FULL_FILE_PATH}: #{error_json}"
          @logger.error(msg)
          puts msg
          exit
        rescue JSON::ParserError
          @logger.info("Successfully downloaded the SPAM user list from #{FULL_FILE_PATH}")
        end
        usernames = res.split(",").map(&:strip)
        delete_spam(usernames)
      end

      private

      def delete_spam(usernames)
        delete_users = []
        delete_projects = []
        delete_notes = []
        delete_reviews = []
        delete_ontologies = []
        delete_prov_classes = []

        usernames.uniq.each do |username|
          user = LinkedData::Models::User.find(username).include(:username).first
          next if user.nil?

          projects = LinkedData::Models::Project.where(creator: user.id).include(:acronym).all
          notes = LinkedData::Models::Note.where(creator: user.id).include(:subject).all
          reviews = LinkedData::Models::Review.where(creator: user.id).include(:body).all
          ontologies = LinkedData::Models::Ontology.where(administeredBy: user.id).include(:acronym).all
          prov_classes = LinkedData::Models::ProvisionalClass.where(creator: user.id).include(:label).all

          @logger.info("User #{user.username} artifacts:")
          @logger.info("--------------------------------")

          pr = projects.map {|p| p.acronym}.join(", ")
          pr = "none" if pr.empty?
          @logger.info("Projects: #{pr}")

          n = notes.map {|n| n.subject}.join(", ")
          n = "none" if n.empty?
          @logger.info("Notes: #{n}")

          rv = reviews.map {|r| r.body}.join(", ")
          rv = "none" if rv.empty?
          @logger.info("Reviews: #{rv}")

          ont = ontologies.map {|o| o.acronym}.join(", ")
          ont = "none" if ont.empty?
          @logger.info("Ontologies: #{ont}")

          pc = prov_classes.map {|p| p.label}.join(", ")
          pc = "none" if pc.empty?
          @logger.info("Provisional Classes: #{pc}")
          @logger.info("--------------------------------\n")
          @logger.flush

          delete_projects.concat projects
          delete_notes.concat notes
          delete_reviews.concat reviews
          delete_ontologies.concat ontologies
          delete_users << user
          delete_prov_classes.concat prov_classes
        end

        if delete_users.length == 0 &&
            delete_projects.length == 0 &&
            delete_notes.length == 0 &&
            delete_reviews.length == 0 &&
            delete_ontologies.length == 0 &&
            delete_prov_classes.length == 0
          @logger.info("No users/projects/notes/reviews/ontologies/provisional classes found")
        else
          @logger.info("Deleting #{delete_projects.length} projects...")
          @logger.info("Deleting #{delete_notes.length} notes...")
          @logger.info("Deleting #{delete_reviews.length} reviews...")
          @logger.info("Deleting #{delete_ontologies.length} ontologies...")
          @logger.info("Deleting #{delete_prov_classes.length} provisional classes...")
          @logger.info("Deleting #{delete_users.length} users...")

          delete_projects.each {|p| p.delete}
          delete_notes.each {|n| n.delete}
          delete_reviews.each {|r| r.delete}
          delete_ontologies.each {|o| o.delete}
          delete_prov_classes.each {|pc| pc.delete}
          delete_users.each {|u| u.delete}
        end
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
# spam_deletion_path = File.join("logs", "spam-deletion.log")
# spam_deletion_logger = Logger.new(spam_deletion_path)
# NcboCron::Models::SpamDeletion.new(spam_deletion_logger).run
# ./bin/ncbo_cron --disable-processing true --disable-pull true --disable-flush true --disable-warmq true --disable-ontology-analytics true --disable-mapping-counts true --disable-ontologies-report true --spam-deletion '14 * * * *'