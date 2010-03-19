module Delayed
  module JobDeprecations
    def self.move_methods_to_worker(*old_methods)
      old_methods.each do |old_method|
        new_method = old_method.to_s.gsub("worker_", "").to_sym
        define_method(old_method) do |*args|
          warn "#{caller[0]}: Job's #{old_method} is deprecated. Use Worker.#{new_method} instead."
          Worker.send(new_method, *args)
        end
      end
    end

    move_methods_to_worker :min_priority,        :min_priority=
    move_methods_to_worker :max_priority,        :max_priority=
    move_methods_to_worker :job_types,           :job_types=
    move_methods_to_worker :destroy_failed_jobs, :destroy_failed_jobs=
    move_methods_to_worker :worker_name,         :worker_name=
  end
end
