# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{delayed_job_on_steroids}
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tobias L\303\274tke", "Aleksey Palazhchenko"]
  s.date = %q{2010-03-15}
  s.description = %q{Delated_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background.}
  s.email = %q{aleksey.palazhchenko@gmail.com}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README.textile",
     "delayed_job_on_steroids.gemspec",
     "generators/delayed_job_migration/delayed_job_migration_generator.rb",
     "generators/delayed_job_migration/templates/migration.rb",
     "init.rb",
     "lib/delayed/job.rb",
     "lib/delayed/message_sending.rb",
     "lib/delayed/performable_method.rb",
     "lib/delayed/worker.rb",
     "lib/delayed_job.rb",
     "spec/database.rb",
     "spec/delayed_method_spec.rb",
     "spec/job_spec.rb",
     "spec/story_spec.rb",
     "tasks/jobs.rake",
     "tasks/tasks.rb"
  ]
  s.homepage = %q{http://github.com/AlekSi/delayed_job_on_steroids}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Database-backed asynchronous priority queue system, extended and improved}
  s.test_files = [
    "spec/delayed_method_spec.rb",
     "spec/job_spec.rb",
     "spec/story_spec.rb",
     "spec/database.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

