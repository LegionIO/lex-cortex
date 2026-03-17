# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Cortex
      module Actor
        class Think < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::Cortex::Runners::Cortex
          end

          def runner_function
            'think'
          end

          def time
            1
          end

          def run_now?
            return false if defined?(Legion::Gaia) && Legion::Gaia.respond_to?(:started?) && Legion::Gaia.started?

            true
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
