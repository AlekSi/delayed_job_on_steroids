module Delayed
  module JobDeprecations
    def self.move_method_to_worker(*old_methods)
      old_methods.each do |old_method|
        define_method(old_method) do |*args, &block|
          warn "#{old_method} is deprecated. Use Worker.#{old_method} instead."
          Worker.send(old_method, *args, &block)
        end
      end
    end

    move_method_to_worker :min_priority, :min_priority=
    move_method_to_worker :max_priority, :max_priority=
    move_method_to_worker :job_types,    :job_types=
  end
end
