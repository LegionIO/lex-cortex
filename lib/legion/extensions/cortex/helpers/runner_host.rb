# frozen_string_literal: true

module Legion
  module Extensions
    module Cortex
      module Helpers
        class RunnerHost
          def initialize(runner_module)
            @runner_module = runner_module
            extend runner_module
          end

          def to_s
            "RunnerHost(#{@runner_module})"
          end

          def inspect
            "#<#{self.class} module=#{@runner_module}>"
          end
        end
      end
    end
  end
end
