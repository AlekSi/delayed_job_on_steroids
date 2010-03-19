module Delayed
  module JobDeprecations
    def self.move_method_to_worker(old_method, new_method)
      define_method(old_method) do |*args, &block|
        warn "#{caller[0]}: #{old_method} is deprecated. Use Worker.#{new_method} instead."
        Worker.send(new_method, *args, &block)
      end
    end

    def self.move_methods_to_worker(*old_methods)
      old_methods.each { |old_method| move_method_to_worker(old_method, old_method) }
    end

    move_methods_to_worker :min_priority,         :min_priority=
    move_methods_to_worker :max_priority,         :max_priority=
    move_methods_to_worker :job_types,            :job_types=
    move_methods_to_worker :destroy_failed_jobs,  :destroy_failed_jobs=

    move_method_to_worker  :worker_name,  :name
    move_method_to_worker  :worker_name=, :name=
  end
end
