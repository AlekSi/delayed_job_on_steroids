# Re-definitions are appended to existing tasks
task :environment

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => [:environment] do
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker (options: MIN_PRIORITY, MAX_PRIORITY, JOB_TYPES)."
  task :work => [:environment] do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'],
      :job_types => ENV['JOB_TYPES']).start
  end
end
