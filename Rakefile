# encoding: utf-8

require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "delayed_job_on_steroids"
    gem.summary = "Database-backed asynchronous priority queue system, extended and improved"
    gem.description = "Delated_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background."
    gem.email = "aleksey.palazhchenko@gmail.com"
    gem.homepage = "http://github.com/AlekSi/delayed_job_on_steroids"
    gem.authors = ["Tobias Lütke", "Aleksey Palazhchenko"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

gem 'rspec', '~>1.2.9'
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec)

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.rcov = true
  spec.rcov_opts = ['--exclude', 'gems']
  spec.verbose = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "delayed_job_on_steroids #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
