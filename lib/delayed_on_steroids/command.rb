require 'optparse'

module Delayed

  # Used by script/delayed_job: parses options, sets logger, invokes Worker.
  class Command
    attr_accessor :worker_count

    def initialize
      @options = {:quiet => false}

      @worker_count = 1

      ARGV.clone.options do |opts|
        opts.separator ""
        opts.on('--min-priority=number', 'Minimum priority of jobs to run.') { |n| @options[:min_priority] = n }
        opts.on('--max-priority=number', 'Maximum priority of jobs to run.') { |n| @options[:max_priority] = n }
        opts.on('--job-types=type', String, 'Type of jobs to run.') { |t| @options[:job_types] = t }
#        opts.on("-d", "--daemon", "Make worker run as a Daemon.") { @options[:detach] = true }
#        opts.on('-n', '--number-of-workers=number', "Number of unique workers to spawn.") { |n| @worker_count = (n.to_i rescue 1) }
#        opts.on("-e", "--environment=name", String,
#          "Specifies the environment to run this worker under (test/development/production).",
#          "Default: development") { |e| @options[:environment] = e }

        opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
        opts.parse!
      end
    end

    def daemonize
      run
    end

    def run(worker_name = nil)
      Dir.chdir(RAILS_ROOT)

      # Replace the default logger... too bad Rails doesn't make this easier
      Rails.logger.instance_eval do
        @log.reopen File.join(RAILS_ROOT, 'log', 'delayed_job.log')
      end
      Delayed::Worker.logger = Rails.logger
      ActiveRecord::Base.connection.reconnect!

      Delayed::Job.worker_name = "#{worker_name} #{Delayed::Job.worker_name}"

      Delayed::Worker.new(@options).start
    rescue => e
      logger.fatal e
      STDERR.puts e.message
      exit 1
    end

  end
end
