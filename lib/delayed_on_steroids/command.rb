require 'optparse'

module Delayed

  # Used by script/delayed_job: parses options, sets logger, invokes Worker.
  class Command
    attr_accessor :worker_count

    def initialize
      @options = {:quiet => false}

      @worker_count = 1

      ARGV.clone.options do |opts|
        opts.separator "Options:"
        opts.on('--worker-name=name', String, 'Worker name. Default is auto-generated.') { |n| @options[:name] = n }
        opts.on('--min-priority=number', 'Minimum priority of jobs to run.') { |n| @options[:min_priority] = n }
        opts.on('--max-priority=number', 'Maximum priority of jobs to run.') { |n| @options[:max_priority] = n }
        opts.on('--job-types=type', String, 'Type of jobs to run.') { |t| @options[:job_types] = t }
        opts.on("-d", "--daemon", "Make worker run as a Daemon.") { @options[:daemon] = true }
#        opts.on('-n', '--number-of-workers=number', "Number of unique workers to spawn.") { |n| @worker_count = (n.to_i rescue 1) }
#        opts.on("-e", "--environment=name", String,
#          "Specifies the environment to run this worker under (test/development/production).",
#          "Default: development") { |e| @options[:environment] = e }

        opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
        opts.parse!
      end
    end

    def run
      Process.daemon if @options[:daemon]

      Dir.chdir(RAILS_ROOT)

      ActiveRecord::Base.connection.reconnect!

      Delayed::Worker.name = @options[:name]

      Delayed::Worker.instance.start
    rescue => e
      logger.fatal(e)
      STDERR.puts(e.message)
      exit 1
    end
  end
end
