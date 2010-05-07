# Re-definitions are appended to existing tasks
task :environment

namespace :jobs do

  namespace :clear do
    desc "Remove failed jobs from delayed_job queue"
    task :failed => [:environment] do
      Delayed::Job.delete_all("failed_at IS NOT NULL")
    end

    desc "Clear entire delayed_job queue"
    task :all => [:environment] do
      Delayed::Job.delete_all
    end
  end

  # Deprecated synonim
  task :clear => ['clear:all']

  desc "Report delayed_job statistics"
  task :stats => [:environment] do
    jobs = Delayed::Job.all
    puts "Active jobs        : #{ jobs.count{ |job| job.locked? } }"
    puts "Scheduled jobs     : #{ jobs.count{ |job| not (job.locked? or job.failed?) } }"
    puts "Failed stored jobs : #{ jobs.count{ |job| job.failed? } }"
  end

  desc "Start single delayed_job worker"
  task :work => [:environment] do
    Delayed::Command.new.run
  end
end
