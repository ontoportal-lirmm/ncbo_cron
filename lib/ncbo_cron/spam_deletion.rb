require 'logger'
require 'benchmark'
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
        auth_token = Base64.decode64(NcboCron.settings.git_repo_access_token)
        @logger.info("Deleting SPAM..."); @logger.flush
        @logger.flush

        time = Benchmark.realtime do
          res = `curl --header 'Authorization: token #{auth_token}' --header 'Accept: application/vnd.github.v3.raw' --location #{FULL_FILE_PATH}`
          usernames = res.split(",").map(&:strip)
          delete_spam(usernames)
        end
        @logger.info("Finished deleting SPAM in #{time} sec."); @logger.flush
      end

      private

      def delete_spam(usernames)
        delete_users = []
        delete_projects = []
        delete_notes = []
        delete_reviews = []

        usernames.uniq.each do |username|
          user = LinkedData::Models::User.find(username).include(:username).first
          next if user.nil?
          projects = LinkedData::Models::Project.where(creator: user.id).include(:acronym).all
          notes = LinkedData::Models::Note.where(creator: user.id).include(:subject).all
          reviews = LinkedData::Models::Review.where(creator: user.id).include(:body).all
          @logger.info("Deleting user #{user.username} projects: #{projects.map {|p| p.acronym}.join(", ")} notes: #{notes.map {|n| n.subject}.join(", ")} and reviews: #{reviews.map {|r| r.body}.join(", ")}")
          @logger.flush
          delete_projects += projects
          delete_notes += notes
          delete_reviews += reviews
          delete_users << user
        end

        if (delete_users.length == 0 &&
            delete_projects.length == 0 &&
            delete_notes.length == 0 &&
            delete_reviews.length == 0)
          @logger.info("No users/projects/notes/reviews found")
        else
          @logger.info("Deleting #{delete_projects.length} projects")
          @logger.info("Deleting #{delete_notes.length} notes")
          @logger.info("Deleting #{delete_reviews.length} reviews")
          @logger.info("Deleting #{delete_users.length} users")
          delete_projects.each {|p| p.delete}
          delete_notes.each {|n| n.delete}
          delete_reviews.each {|r| r.delete}
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