class CreateDelayedJobs < ActiveRecord::Migration
  def self.up
    create_table :delayed_jobs, :force => true do |table|
      table.integer  :priority,  :null => false, :default => 0  # Allows some jobs to jump to the front of the queue.
      table.integer  :attempts,  :null => false, :default => 0  # Provides for retries, but still fail eventually.
      table.text     :handler,   :null => false                 # YAML-encoded string of the object that will do work.
      table.string   :job_type,  :null => false                 # Class name of the job object, for type-specific workers.
      table.string   :job_tag                                   # Helps to locate this job among others of the same type in your application.
      table.string   :last_error                                # Reason for last failure.
      table.datetime :run_at,    :null => false                 # When to run. Could be Job.db_time_now for immediately, or sometime in the future.
      table.datetime :locked_at                                 # Set when a client is working on this object.
      table.string   :locked_by                                 # Who is working on this object (if locked).
      table.datetime :failed_at                                 # Set when all retries have failed (actually, by default, the record is deleted instead).
      table.timestamps
    end

    add_index :delayed_jobs, :priority
    add_index :delayed_jobs, :job_type
    add_index :delayed_jobs, :job_tag
    add_index :delayed_jobs, :run_at
    add_index :delayed_jobs, :locked_at
    add_index :delayed_jobs, :locked_by
    add_index :delayed_jobs, :failed_at
  end

  def self.down
    drop_table :delayed_jobs
  end
end
