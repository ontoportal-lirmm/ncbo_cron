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
        update_check_enabled = NcboCron.settings.enable_update_check
        info = {update_check_enabled: update_check_enabled}

        if update_check_enabled
          r = redis
          info_raw = r.get(REDIS_UPDATE_INFO_KEY)
          check_for_update if info_raw.nil?
          info_raw = r.get(REDIS_UPDATE_INFO_KEY)
          info_marshalled = Marshal.load(info_raw)

          # last update check resulted in an error. Recheck!
          if info_marshalled.key?(:error)
            check_for_update
            info_raw = r.get(REDIS_UPDATE_INFO_KEY)
            info_marshalled = Marshal.load(info_raw)
          end

          info.merge!(info_marshalled) unless info_marshalled.nil?
        end
        info
      end

      def check_for_update
        rh = {}

        begin
          id = iid
          lv = local_version
          response_raw = RestClient.get(BP_UPDATECHECK_URL.call(id, lv))
          response = JSON.parse(response_raw)
          # check whether json came as Hash or String
          rh = response.class == String ? eval(response) : response
          # check for booleans expressed as strings in json
          rh.each { |key, v| rh[key] = true if v.to_s.downcase == "true"; rh[key] = false if v.to_s.downcase == "false"}
          rh[:current_version] = lv
          tm = DateTime.now
          tm_str = tm.strftime("%m/%d/%Y, %I:%M %p")
          rh[:date_checked] = tm_str
          rh[:appliance_id] = id
        rescue Exception => e
          if e.class == RestClient::NotFound
            msg = "Unable to connect to the update server"
          elsif e.class == Errno::EACCES
            msg = "Unable to retrieve the current version number"
          else
            msg = "Unable to check for update - #{e.class}: #{e.message}"
          end

          rh[:error] = msg
          @logger.error("Unable to check for update - #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end

        r = redis
        r.set(REDIS_UPDATE_INFO_KEY, Marshal.dump(rh))
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

