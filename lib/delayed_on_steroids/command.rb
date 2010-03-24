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
        opts.on('--log-file=file', String, 'Use specified file to log instead of Rails default logger.') do |f|
          Delayed::Worker.logger = ActiveSupport::BufferedLogger.new(f)
        end
        opts.on("-q", "--quiet", "Be quieter.")                                          { @quiet = true }
        opts.on("-d", "--daemon", "Make worker run as a Daemon.")                        { @run_as_daemon = true }
        opts.on('-n', '--number-of-workers=number', Integer, "Number of unique workers to spawn. Implies -d option if number > 1.") do |n|
          @worker_count = ([n, 1].max rescue 1)
          @run_as_daemon ||= (@worker_count > 1)
        end
        opts.on("-e", "--environment=name", String,
          "Specifies the environment to run this worker under (test/development/production/etc).") do |e|
          ENV["RAILS_ENV"] = e
          RAILS_ENV.replace(e)
        end

        opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
        opts.parse!
      end
    end

    def spawn_workers
      # fork children if needed
      worker_no = nil
      if @worker_count > 1
        it_is_parent = true
        @worker_count.times do |no|
          it_is_parent = fork
          worker_no = no
          break unless it_is_parent
        end
        exit 0 if it_is_parent
      end

      Process.daemon if @run_as_daemon

      if Delayed::Worker.name.nil?
        Delayed::Worker.name = ("host:#{Socket.gethostname} " rescue "") + "pid:#{Process.pid}"
      else
        Delayed::Worker.name += worker_no.to_s
      end
    end

    def write_pid
      pid = "#{RAILS_ROOT}/tmp/pids/dj_#{Delayed::Worker.name.parameterize('_')}.pid"
      File.open(pid, 'w') { |f| f.write(Process.pid) }
      at_exit { File.delete(pid) if File.exist?(pid) }
    end

    def setup_logger
      if Delayed::Worker.logger.respond_to?(:auto_flushing=)
        Delayed::Worker.logger.auto_flushing = true
      end

      if @quiet and Delayed::Worker.logger.respond_to?(:level=)
        if Delayed::Worker.logger.kind_of?(Logger)
          Delayed::Worker.logger.level = Logger::Severity::INFO
        elsif Delayed::Worker.logger.kind_of?(ActiveSupport::BufferedLogger)
          Delayed::Worker.logger.level = ActiveSupport::BufferedLogger::Severity::INFO
       end
      end

      ActiveRecord::Base.logger = Delayed::Worker.logger
    end

    def run
      warn "Running in #{RAILS_ENV} environment!" if RAILS_ENV.include?("dev") or RAILS_ENV.include?("test")

      # Saves memory with Ruby Enterprise Edition
      if GC.respond_to?(:copy_on_write_friendly=)
        GC.copy_on_write_friendly = true
      end

      spawn_workers
      Dir.chdir(RAILS_ROOT)
      write_pid
      setup_logger
      ActiveRecord::Base.connection.reconnect!

      Delayed::Worker.instance.start
    rescue => e
      Delayed::Worker.logger.fatal(e)
      STDERR.puts(e.message)
      exit 1
    end
  end
end
