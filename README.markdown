Delayed::Job (on steroids)
==========================

delayed_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. 
Amongst those tasks are:

* sending massive newsletters
* image resizing
* http downloads
* updating smart collections
* updating solr
* batch imports 
* spam checks


Setup
-----

The library evolves around a delayed_jobs table which can be created by using:

	script/generate delayed_job_migration

The created table looks as follows: 

	create_table :delayed_jobs, :force => true do |table|
	  table.integer  :priority,  :null => false, :default => 0  # Allows some jobs to jump to the front of the queue.
	  table.integer  :attempts,  :null => false, :default => 0  # Provides for retries, but still fail eventually.
	  table.text     :handler,   :null => false                 # YAML-encoded string of the object that will do work.
	  table.string   :job_type,  :null => false                 # Class name of the job object, for type-specific workers.
	  table.string   :job_tag                                   # Helps to locate this job among others of the same type in your application.
	  table.string   :last_error                                # Reason for last failure.
	  table.datetime :run_at,    :null => false                 # When to run. Could be Job.db_time_now or some time in the future.
	  table.datetime :locked_at                                 # Set when a client is working on this object.
	  table.string   :locked_by                                 # Who is working on this object (if locked).
	  table.datetime :failed_at                                 # Set when all retries have failed (actually, by default, the record is deleted instead).
	  table.timestamps
	end

On failure, the job is scheduled again in 5 seconds + N ** 4, where N is the number of retries.

The default `MAX_ATTEMPTS` is `25`. After this, the job either deleted (default), or left in the database with `failed_at` set.
With the default of 25 attempts, the last retry will be 20 days later, with the last interval being almost 100 hours.

The default `MAX_RUN_TIME` is `4.hours`. If your job takes longer than that, another computer could pick it up. It's up to you to
make sure your job doesn't exceed this time. You should set this to the longest time you think the job could take.

By default, it will delete failed jobs (and it always deletes successful jobs). If you want to keep failed jobs, set `Delayed::Worker.destroy_failed_jobs = false`. The failed jobs will be marked with non-null `failed_at`.

Here is an example of changing job parameters in Rails:

	# config/initializers/delayed_job_config.rb
	Delayed::Worker.destroy_failed_jobs = false
	silence_warnings do
	  Delayed::Job.const_set("MAX_ATTEMPTS", 3)
	  Delayed::Job.const_set("MAX_RUN_TIME", 5.minutes)
	end


Usage
-----

Jobs are simple ruby objects with a method called perform. Any object which responds to perform can be stuffed into the jobs table.
Job objects are serialized to yaml so that they can later be resurrected by the job runner. 

	class NewsletterJob < Struct.new(:text, :emails)
	  def perform
	    emails.each { |e| NewsletterMailer.deliver_text_to_email(text, e) }
	  end    
	end  

	Delayed::Job.enqueue(NewsletterJob.new('lorem ipsum...', Customers.find(:all).collect(&:email)))

There is also a second way to get jobs in the queue: send_later. 

	BatchImporter.new(Shop.find(1)).send_later(:import_massive_csv, massive_csv)

This will simply create a `Delayed::PerformableMethod` job in the jobs table which serializes all the parameters you pass to it. There are some special smarts for active record objects which are stored as their text representation and loaded from the database fresh when the job is actually run later.
                                                                                                                              
                                                                                                                    
Running the jobs
----------------

Run `script/generate delayed_job` to add `script/delayed_job`. This script can then be used to manage a process which will start working off jobs.

	$ ruby script/delayed_job -h

Workers can be running on any computer, as long as they have access to the database and their clock is in sync. You can even
run multiple workers on per computer, but you must give each one a unique name (`script/delayed_job` will do it for you).
Keep in mind that each worker will check the database at least every 5 seconds.


About this fork
---------------

This fork was born to introduce new features to delayed_job, but also to be almost-fully compatible with it.


Incompatibilities with tobi's delayed_job
-----------------------------------------

* Database schema:
 * `last_error` column's type changed from string to text;
 * some columns are NOT NULL now.
* Invert meaning of `priority` field: job with lesser priority will be executed earlier. See http://www.elevatedcode.com/articles/2009/11/04/speeding-up-delayed-job/ for background.


Changes
-------

* 2.0:
 * Added `script/delayed_job` - runs as daemon, several workers concurrently, minimal and maximal priority, job type, logger, etc.
 * Added rake tasks: `jobs:clear:all`, `jobs:clear:failed`, `jobs:stats`.
 * Added timeout for job execution.
 * Added `send_at` method for queueing jobs in the future.
 * Consume less memory with Ruby Enterprise Edition.

* 1.7.5:
 * Added possibility to run only specific types of jobs.
