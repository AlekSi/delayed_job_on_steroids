module Delayed
  class Worker
    include Singleton

    SLEEP = 5

    cattr_accessor :logger
    self.logger = if defined?(RAILS_DEFAULT_LOGGER)
      RAILS_DEFAULT_LOGGER
    end

    cattr_accessor :min_priority, :max_priority
    cattr_accessor :job_types
    cattr_accessor :quiet

    # Every worker should has a unique name.
    # If wasn't assigned, it will be generated from the hostname and the pid of the process at +start+.
    # There is advantage to assign name manually:
    # workers can safely resume working on tasks which are locked by themselves (the worker will assume that it crashed before).
    cattr_accessor :name

    # By default failed jobs are destroyed after too many attempts.
    # If you want to keep them around (perhaps to inspect the reason for the failure), set this to false.
    cattr_accessor :destroy_failed_jobs
    @@destroy_failed_jobs = true

    # Starts worker
    def start
      @@name ||= ("host:#{Socket.gethostname} " rescue "") + "pid:#{Process.pid}"
      say "*** Starting job worker #{@@name}"

      trap('TERM') { say 'Exiting...'; $exit = true }
      trap('INT')  { say 'Exiting...'; $exit = true }

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
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        break if $exit
      end

    ensure
      # When a worker is exiting, make sure we don't have any locked jobs.
      Delayed::Job.update_all("locked_by = null, locked_at = null", ["locked_by = ?", @@name])
    end

    def say(text)
      puts text unless quiet
      logger.info text if logger
    end

  end
end
