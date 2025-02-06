require 'logger'
# Scheduling/lock gems
require 'redis-lock'
require 'rufus-scheduler'

module NcboCron
  class Scheduler
    class << self
      attr_reader :scheduler

      def scheduled_locking_job(options = {}, &block)
        lock_life       = options[:life] || 10*60
        job_name        = options[:job_name] || "ncbo_cron"
        logger          = options[:logger] || Logger.new($stdout)
        relock_period   = options[:relock_period] || lock_life - 15
        redis_host      = options[:redis_host] || "localhost"
        redis_port      = options[:redis_port] || 6379
        process         = options[:process]
        minutes_between = options[:minutes_between]
        seconds_between = options[:seconds_between]
        scheduler_type  = options[:scheduler_type] || :every
        cron_schedule   = options[:cron_schedule]

        # Determine interval based on scheduler type
        if scheduler_type == :every
          interval = if seconds_between
                       "#{seconds_between}s"
                     elsif minutes_between
                       "#{minutes_between}m"
                     else
                       "5m"
                     end
        elsif scheduler_type == :cron
          interval = cron_schedule
        end

        redis = Redis.new(host: redis_host, port: redis_port)

        # Initialize scheduler only if it's not already running
        @scheduler ||= begin
                         s = Rufus::Scheduler.new(
                           lockfile: nil, # Disable file locking as we're using Redis
                           thread_name: "scheduler_#{job_name}"
                         )

                         # Add shutdown hook for clean termination
                         Signal.trap('TERM') do
                           s.shutdown(:wait)
                           exit
                         end

                         s
                       end

        begin
          # Schedule the job based on type
          @scheduler.send(scheduler_type, interval, job: true, overlap: false, tag: job_name) do
            redis.lock(job_name, life: lock_life, owner: "ncbo_cron") do
              pid = fork do
                $0 = job_name # rename the process
                begin
                  logger.debug("#{job_name} -- Lock acquired")
                  logger.flush

                  # Create a thread for lock renewal
                  renewal_thread = Thread.new do
                    loop do
                      sleep(relock_period)
                      begin
                        logger.debug("Re-locking for #{lock_life}")
                        redis.extend_lock(job_name, life: lock_life)
                      rescue => e
                        logger.error("Lock renewal failed: #{e.message}")
                        break
                      end
                    end
                  end

                  # Run the process
                  yield if block_given?
                  process&.call

                ensure
                  renewal_thread&.kill
                  Kernel.exit!
                end
              end

              logger.debug("#{job_name} -- running in pid #{pid}")
              logger.flush
              Process.wait(pid)
            end
          end
        rescue Rufus::Scheduler::NotRunningError => e
          logger.error("Failed to schedule job: #{e.message}")
          raise
        end

        # Wait for scheduling
        @scheduler.join unless @scheduler.nil?
      end
    end
  end
end
