module Delayed
  class Worker
    include Singleton

    SLEEP = 5

    cattr_accessor :logger
    @@logger = Rails.logger if defined?(Rails)

    cattr_accessor :min_priority, :max_priority
    cattr_accessor :job_types

    # Every worker should has a unique name. If you start worker via +delayed_job+ script, name will be generated
    # automatically based on the hostname and the pid of the process.
    # There is advantage to assign name manually:
    # workers can safely resume working on tasks which are locked by themselves (the worker will assume that it crashed before).
    cattr_accessor :name

    # By default failed jobs are destroyed after too many attempts.
    # If you want to keep them around (perhaps to inspect the reason for the failure), set this to false.
    cattr_accessor :destroy_failed_jobs
    @@destroy_failed_jobs = true

    # Starts worker
    def start
      @@logger.info("* [#{@@name}] Starting job worker...")

      trap('TERM') { @@logger.info("* [#{@@name}] Exiting..."); $exit = true }
      trap('INT')  { @@logger.info("* [#{@@name}] Exiting..."); $exit = true }

      loop do
        result = nil

        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end

        count = result.sum

        break if $exit

        if count.zero?
          sleep(SLEEP)
        else
          @@logger.info("* [#{@@name}] #{count} jobs processed at %.4f j/s, %d failed..." % [count / realtime, result.last])
        end

        break if $exit
      end

    ensure
      # When a worker is exiting, make sure we don't have any locked jobs.
      Delayed::Job.update_all("locked_by = null, locked_at = null", ["locked_by = ?", @@name])
    end
  end
end
