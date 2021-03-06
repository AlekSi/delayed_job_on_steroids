require 'timeout'

module Delayed

  class DeserializationError < StandardError
  end

  # A job object that is persisted to the database.
  # Contains the work object as a YAML field +handler+.
  class Job < ActiveRecord::Base
    set_table_name :delayed_jobs
    before_save { |job| job.run_at ||= job.class.db_time_now }

    extend JobDeprecations

    MAX_ATTEMPTS = 25
    MAX_RUN_TIME = 4.hours

    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

    # Returns +true+ if current job failed.
    def failed?
      not failed_at.nil?
    end
    alias_method :failed, :failed?

    # Returns +true+ if current job locked.
    def locked?
      not locked_at.nil?
    end
    alias_method :locked, :locked?

    def payload_object
      @payload_object ||= deserialize(self['handler'])
    end

    def payload_object=(object)
      self['job_type'] = object.class.to_s
      self['handler']  = object.to_yaml
    end

    # Returns job name.
    def name
      @name ||= begin
        payload = payload_object
        if payload.respond_to?(:display_name)
          payload.display_name
        else
          payload.class.name
        end
      end
    end

    # Reschedule the job to run at +time+ (when a job fails).
    # If +time+ is nil it uses an exponential scale depending on the number of failed attempts.
    def reschedule(message, backtrace = [], time = nil)
      if (self.attempts += 1) < MAX_ATTEMPTS
        time ||= Job.db_time_now + (attempts ** 4) + 5

        self.run_at       = time
        self.last_error   = message + "\n" + backtrace.join("\n")
        self.locked_at    = nil
        self.locked_by    = nil
        save!
      else
        Worker.logger.warn("* [#{Worker.name}] PERMANENTLY removing #{self.name} because of #{attempts} consequetive failures.")
        Worker.destroy_failed_jobs ? destroy : update_attribute(:failed_at, self.class.db_time_now)
      end
    end

    # Try to run one job. Returns true/false (work done/work failed) or nil if job can't be locked.
    def run_with_lock(max_run_time = MAX_RUN_TIME, worker_name = Worker.name)
      Worker.logger.info("* [#{Worker.name}] acquiring lock on #{name}")
      unless lock_exclusively!(max_run_time, worker_name)
        # We did not get the lock, some other worker process must have
        Worker.logger.warn("* [#{Worker.name}] failed to acquire exclusive lock for #{name}")
        return nil # no work done
      end

      begin
        runtime =  Benchmark.realtime do
          Timeout.timeout(max_run_time.to_i) { invoke_job }
          destroy
        end
        Worker.logger.info("* [#{Worker.name}] #{name} completed after %.4f" % runtime)
        return true  # did work
      rescue Exception => e
        reschedule(e.message, e.backtrace)
        log_exception(e)
        return false  # work failed
      end
    end

    # Add a job to the queue. Arguments: priority, run_at.
    def self.enqueue(*args, &block)
      object = block_given? ? EvaledJob.new(&block) : args.shift

      unless object.respond_to?(:perform) || block_given?
        raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
      end

      priority = args[0] || 0
      run_at   = args[1]

      Job.create(:payload_object => object, :priority => priority.to_i, :run_at => run_at)
    end

    # Find a few candidate jobs to run (in case some immediately get locked by others).
    def self.find_available(limit = 5, max_run_time = MAX_RUN_TIME)
      time_now = db_time_now
      sql = ''
      conditions = []

      # 1) not scheduled in the future
      sql << '(run_at <= ?)'
      conditions << time_now

      # 2) and job is not failed yet
      sql << ' AND (failed_at IS NULL)'

      # 3a) and already locked by same worker
      sql << ' AND ('
      sql << '(locked_by = ?)'
      conditions << Worker.name

      # 3b) or not locked yet
      sql << ' OR (locked_at IS NULL)'

      # 3c) or lock expired
      sql << ' OR (locked_at < ?)'
      sql << ')'
      conditions << time_now - max_run_time

      if Worker.min_priority
        sql << ' AND (priority >= ?)'
        conditions << Worker.min_priority
      end

      if Worker.max_priority
        sql << ' AND (priority <= ?)'
        conditions << Worker.max_priority
      end

      if Worker.job_types
        sql << ' AND (job_type IN (?))'
        conditions << Worker.job_types
      end

      conditions.unshift(sql)
      find(:all, :conditions => conditions, :order => 'priority ASC, run_at ASC', :limit => limit)
    end

    # Run the next job we can get an exclusive lock on.
    # If no jobs are left we return nil
    def self.reserve_and_run_one_job(max_run_time = MAX_RUN_TIME)

      # We get up to 20 jobs from the db. In case we cannot get exclusive access to a job we try the next.
      # this leads to a more even distribution of jobs across the worker processes
      find_available(20, max_run_time).each do |job|
        t = job.run_with_lock(max_run_time, Worker.name)
        return t unless t == nil  # return if we did work (good or bad)
      end

      nil # we didn't do any work, all 20 were not lockable
    end

    # Lock this job for this worker.
    # Returns true if we have the lock, false otherwise.
    def lock_exclusively!(max_run_time = MAX_RUN_TIME, worker_name = Worker.name)
      now = self.class.db_time_now
      affected_rows = if locked_by != worker_name
        # We don't own this job so we will update the locked_by name and the locked_at
        self.class.update_all(["locked_at = ?, locked_by = ?", now, worker_name], ["id = ? and (locked_at is null or locked_at < ?) and (run_at <= ?)", id, (now - max_run_time.to_i), now])
      else
        # We already own this job, this may happen if the job queue crashes.
        # Simply resume and update the locked_at
        self.class.update_all(["locked_at = ?", now], ["id = ? and locked_by = ?", id, worker_name])
      end
      if affected_rows == 1
        self.locked_at    = now
        self.locked_by    = worker_name
        return true
      else
        return false
      end
    end

    # This is a good hook if you need to report job processing errors in additional or different ways
    def log_exception(e)
      Worker.logger.error("! [#{Worker.name}] #{name} failed with #{e.class.name}: #{e.message} - #{attempts} failed attempts")
      Worker.logger.error(e)
    end

    # Do num jobs and return stats on success/failure.
    # Exit early if interrupted.
    def self.work_off(num = 100)
      success, failure = 0, 0

      num.times do
        case self.reserve_and_run_one_job
        when true
            success += 1
        when false
            failure += 1
        else
          break  # leave if no work could be done
        end
        break if $exit # leave if we're exiting
      end

      return [success, failure]
    end

    # Moved into its own method so that new_relic can trace it.
    def invoke_job
      payload_object.perform
    end

    # Get the current time (GMT or local depending on DB)
    # Note: This does not ping the DB to get the time, so all your clients
    # must have syncronized clocks.
    def self.db_time_now
      if Time.zone
        Time.zone.now
      elsif ActiveRecord::Base.default_timezone == :utc
        Time.now.utc
      else
        Time.now
      end
    end

   private

    def deserialize(source)
      handler = YAML.load(source) rescue nil

      unless handler.respond_to?(:perform)
        if handler.nil? && source =~ ParseObjectFromYaml
          handler_class = $1
        end
        attempt_to_load(handler_class || handler.class)
        handler = YAML.load(source)
      end

      return handler if handler.respond_to?(:perform)

      raise DeserializationError,
        'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
    rescue TypeError, LoadError, NameError => e
      raise DeserializationError,
        "Job failed to load: #{e.message}. Try to manually require the required file."
    end

    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    def attempt_to_load(klass)
       klass.constantize
    end

  end

  class EvaledJob
    def initialize
      @job = yield
    end

    def perform
      eval(@job)
    end
  end
end
