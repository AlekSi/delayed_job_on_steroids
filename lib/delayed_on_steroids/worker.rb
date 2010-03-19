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

    # Every worker has a unique name which by default is the hostname and the pid of the process.
    # There is advantage to overriding this with something which survives worker restarts:
    # workers can safely resume working on tasks which are locked by themselves (the worker will assume that it crashed before).
    cattr_accessor :name
    @@name = ("host:#{Socket.gethostname} " rescue "") + "pid:#{Process.pid}"

    # By default failed jobs are destroyed after too many attempts.
    # If you want to keep them around (perhaps to inspect the reason for the failure), set this to false.
    cattr_accessor :destroy_failed_jobs
    @@destroy_failed_jobs = true

    def initialize
      # Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      # Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
      # Delayed::Job.job_types    = options[:job_types]    if options.has_key?(:job_types)
    end

    # Starts worker
    def start
      say "*** Starting job worker #{Delayed::Job.worker_name}"

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
      Delayed::Job.clear_locks!
    end

    def say(text)
      puts text unless quiet
      logger.info text if logger
    end

  end
end
