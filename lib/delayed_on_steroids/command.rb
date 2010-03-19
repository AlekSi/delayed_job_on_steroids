require 'optparse'

module Delayed

  # Used by script/delayed_job: parses options, sets logger, invokes Worker.
  class Command

    def initialize
      @worker_count = 1
      @run_as_daemon = false

      ARGV.clone.options do |opts|
        opts.separator "Options:"
        opts.on('--worker-name=name', String, 'Worker name. Default is auto-generated.') { |n| Delayed::Worker.name = n }
        opts.on('--min-priority=number', Integer, 'Minimum priority of jobs to run.')    { |n| Delayed::Worker.min_priority = n }
        opts.on('--max-priority=number', Integer, 'Maximum priority of jobs to run.')    { |n| Delayed::Worker.max_priority = n }
        opts.on('--job-types=types', String, 'Type of jobs to run.')                     { |t| Delayed::Worker.job_types = t.split(',') }
        opts.on('--keep-failed-jobs', 'Do not remove failed jobs from database.')        { Delayed::Worker.destroy_failed_jobs = false }
        opts.on("-d", "--daemon", "Make worker run as a Daemon.")                        { @run_as_daemon = true }
        opts.on('-n', '--number-of-workers=number', Integer, "Number of unique workers to spawn. Implies -d option if number > 1.") do |n|
          @worker_count = ([n, 1].max rescue 1)
          @run_as_daemon ||= (@worker_count > 1)
        end
#        opts.on("-e", "--environment=name", String,
#          "Specifies the environment to run this worker under (test/development/production).",
#          "Default: development") { |e| @options[:environment] = e }

        opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
        opts.parse!
      end
    end

    def spawn_workers
      return if @worker_count == 1
      while @worker_count > 0
        it_is_parent = fork
        return unless it_is_parent
        @worker_count -= 1
      end
      exit 0
    end

    def run
      spawn_workers
      Process.daemon if @run_as_daemon

      Dir.chdir(RAILS_ROOT)

      Delayed::Worker.instance.start
    rescue => e
      logger.fatal(e) if defined?(logger)
      STDERR.puts(e.message)
      exit 1
    end
  end
end
