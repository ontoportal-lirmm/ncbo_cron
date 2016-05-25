require 'logger'
require 'benchmark'

module NcboCron
  module Models

    class SpamDeletion
      AUTH_TOKEN = "77e7caed29f4933ac8c8c53aa1d5bf3b6e2f84a6"
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
        @logger.info("Deleting SPAM..."); @logger.flush
        @logger.flush

        time = Benchmark.realtime do





          # curl --header 'Authorization: token $AUTH_TOKEN' --header 'Accept: application/vnd.github.v3.raw' --remote-name --location FULL_FILE_PATH
          # system("curl -s -o /dev/null -u #{Jiralicious.username}:#{Jiralicious.password} -X POST -H 'X-Atlassian-Token: nocheck' -F 'file=@#{cron_parsing_errorsfile}' #{issue_attachment_url}")

          # f = system("curl --header 'Authorization: token #{AUTH_TOKEN}' --header 'Accept: application/vnd.github.v3.raw' --remote-name --location #{FULL_FILE_PATH}")

          t = "curl --header 'Authorization: token #{AUTH_TOKEN}' --header 'Accept: application/vnd.github.v3.raw' --remote-name --location #{FULL_FILE_PATH}"

          puts `curl --header 'Authorization: token #{AUTH_TOKEN}' --header 'Accept: application/vnd.github.v3.raw' --remote-name --location #{FULL_FILE_PATH}`


          puts t
# binding.pry


        end
        @logger.info("Finished deleting SPAM in #{time} sec."); @logger.flush
      end

    end
  end
end

require 'ontologies_linked_data'
require 'goo'
require 'ncbo_annotator'
require 'ncbo_cron/config'
require_relative '../../config/config'

spam_deletion_path = File.join("logs", "spam-deletion.log")
spam_deletion_logger = Logger.new(spam_deletion_path)
NcboCron::Models::SpamDeletion.new(spam_deletion_logger).run