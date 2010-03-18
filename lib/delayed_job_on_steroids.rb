autoload :ActiveRecord, 'active_record'

require File.dirname(__FILE__) + '/delayed_on_steroids/message_sending'
require File.dirname(__FILE__) + '/delayed_on_steroids/performable_method'
require File.dirname(__FILE__) + '/delayed_on_steroids/job'
require File.dirname(__FILE__) + '/delayed_on_steroids/worker'

Object.send(:include, Delayed::MessageSending)   
Module.send(:include, Delayed::MessageSending::ClassMethods)
