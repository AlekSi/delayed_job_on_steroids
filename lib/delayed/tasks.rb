# Re-definitions are appended to existing tasks
task :environment

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => [:environment] do
    Delayed::Job.delete_all
  end
end
