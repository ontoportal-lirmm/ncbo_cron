require 'logger'
require 'benchmark'
require 'fileutils'
require 'rest-client'
require 'json'
require 'securerandom'
require 'parseconfig'

module NcboCron
  module Models
    class UpdateManager
      class UpdateManagerError < StandardError; end

      BP_UPDATECHECK_URL = lambda { |iid, local_version| "#{NcboCron.settings.update_check_endpoint_url}?iid=#{iid}&version=#{local_version}" }
      REDIS_INSTANCE_ID_KEY = "ontoportal.instance.id"
      REDIS_UPDATE_INFO_KEY = "ontoportal.update.info"

      def initialize(logger=nil)
        @logger = nil

        if logger.nil?
          log_file = File.new(NcboCron.settings.log_path, "a")
          log_path = File.dirname(File.absolute_path(log_file))
          log_filename_no_ext = File.basename(log_file, ".*")
          update_manager_log_path = File.join(log_path, "#{log_filename_no_ext}-update-manager.log")
          @logger = Logger.new(update_manager_log_path)
        else
          @logger = logger
        end
      end

      def run
        check_for_update
      end

      def update_info
        r = redis
        info = r.get(REDIS_UPDATE_INFO_KEY)
        info.nil? ? Hash.new : Marshal.load(info)
      end

      def check_for_update
        lv = local_version
        id = iid

        begin
          response_raw = RestClient.get(BP_UPDATECHECK_URL.call(id, lv))
          response = JSON.parse(response_raw)
          rh = eval(response)
          rh[:current_version] = lv
          d = DateTime.now
          rh[:date_checked] = d.strftime
          r = redis
          r.set(REDIS_UPDATE_INFO_KEY, Marshal.dump(rh))
        rescue Exception => e
          @logger.error("Unable to check for update - #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end

      def iid
        r = redis
        inst_id = r.get(REDIS_INSTANCE_ID_KEY)

        if inst_id.nil?
          inst_id = SecureRandom.uuid
          r.set(REDIS_INSTANCE_ID_KEY, inst_id)
        end
        inst_id
      end

      def local_version
        config = ParseConfig.new(NcboCron.settings.versions_file_path)
        config['APPLIANCE_VERSION']
      end

      def redis
        Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port)
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
# update_manager_path = File.join("logs", "update-manager.log")
# update_manager_logger = Logger.new(update_manager_path)
# NcboCron::Models::UpdateManager.new(update_manager_logger).run

