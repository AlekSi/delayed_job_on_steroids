$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/../../rspec/lib')

require 'rubygems'
require 'active_record'
gem 'sqlite3-ruby'

require File.dirname(__FILE__) + '/../init'
require 'spec'

Delayed::Worker.logger = Logger.new('/tmp/dj.log')
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => '/tmp/jobs.sqlite')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do

  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority,  :null => false, :default => 0
    table.integer  :attempts,  :null => false, :default => 0
    table.text     :handler,   :null => false
    table.string   :job_type,  :null => false
    table.string   :job_tag
    table.string   :last_error
    table.datetime :run_at,    :null => false
    table.datetime :locked_at
    table.string   :locked_by
    table.datetime :failed_at
    table.timestamps
  end

  add_index :delayed_jobs, [:priority, :run_at]
  add_index :delayed_jobs, :job_type
  add_index :delayed_jobs, :job_tag
  add_index :delayed_jobs, :run_at
  add_index :delayed_jobs, :locked_at
  add_index :delayed_jobs, :locked_by
  add_index :delayed_jobs, :failed_at

  create_table :stories, :force => true do |table|
    table.string :text
  end

end


# Purely useful for test cases...
class Story < ActiveRecord::Base
  def tell; text; end
  def whatever(n, _); tell*n; end

  handle_asynchronously :whatever
end
