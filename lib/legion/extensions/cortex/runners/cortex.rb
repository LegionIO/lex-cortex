# frozen_string_literal: true

module Legion
  module Extensions
    module Cortex
      module Runners
        module Cortex
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def think(**)
            signals = signal_buffer.drain

            # Lazy-wire on first tick or after rewire
            wire_phase_handlers if @phase_handlers.nil?

            # Resolve the tick orchestrator
            tick_host = runner_instances[:Tick_Orchestrator]
            unless tick_host
              Legion::Logging.warn '[cortex] lex-tick not available, cannot think'
              return { error: :no_tick_extension }
            end

            wired_count = @phase_handlers.size
            Legion::Logging.debug "[cortex] think: signals=#{signals.size} wired_phases=#{wired_count}"

            result = tick_host.execute_tick(signals: signals, phase_handlers: @phase_handlers)

            # Collect valences for next tick's gut instinct
            if result.is_a?(Hash) && result[:results]
              valence_result = result[:results][:emotional_evaluation]
              @last_valences = [valence_result[:valence]] if valence_result.is_a?(Hash) && valence_result[:valence]
            end

            result
          end

          def ingest_signal(signal: {}, source_type: :ambient, salience: 0.0, **)
            normalized = signal.is_a?(Hash) ? signal : { value: signal }
            normalized[:source_type] = source_type
            normalized[:salience] = salience

            signal_buffer.push(normalized)
            Legion::Logging.debug "[cortex] signal ingested: source=#{source_type} salience=#{salience} buffer=#{signal_buffer.size}"
            { ingested: true, buffer_depth: signal_buffer.size }
          end

          def cortex_status(**)
            discovery = Helpers::Wiring.discover_available_extensions
            loaded = discovery.count { |_, v| v[:loaded] }
            total = discovery.size
            wired = @phase_handlers&.size || 0

            Legion::Logging.debug "[cortex] status: extensions=#{loaded}/#{total} wired_phases=#{wired} buffer=#{signal_buffer.size}"
            {
              extensions_available: loaded,
              extensions_total:     total,
              wired_phases:         wired,
              phase_list:           @phase_handlers&.keys || [],
              buffer_depth:         signal_buffer.size,
              discovery:            discovery
            }
          end

          def rewire(**)
            @runner_instances = nil
            @phase_handlers = nil
            wire_phase_handlers

            wired = @phase_handlers.size
            Legion::Logging.info "[cortex] rewired: #{wired} phases connected"
            { rewired: true, wired_phases: wired, phase_list: @phase_handlers.keys }
          end

          private

          def signal_buffer
            @signal_buffer ||= Helpers::SignalBuffer.new
          end

          def runner_instances
            @runner_instances ||= build_runner_instances
          end

          def build_runner_instances
            instances = {}

            # Always wire tick orchestrator
            tick_class = Helpers::Wiring.resolve_runner_class(:Tick, :Orchestrator)
            instances[:Tick_Orchestrator] = Helpers::RunnerHost.new(tick_class) if tick_class

            # Wire all phase map entries
            Helpers::Wiring::PHASE_MAP.each_value do |mapping|
              next if mapping.nil?

              key = :"#{mapping[:ext]}_#{mapping[:runner]}"
              next if instances.key?(key)

              runner_class = Helpers::Wiring.resolve_runner_class(mapping[:ext], mapping[:runner])
              if runner_class
                instances[key] = Helpers::RunnerHost.new(runner_class)
                Legion::Logging.debug "[cortex] wired: #{mapping[:ext]}::#{mapping[:runner]}"
              else
                Legion::Logging.debug "[cortex] skipped: #{mapping[:ext]}::#{mapping[:runner]} (not loaded)"
              end
            end

            instances
          end

          def wire_phase_handlers
            @phase_handlers = Helpers::Wiring.build_phase_handlers(runner_instances)
            Legion::Logging.info "[cortex] phase handlers built: #{@phase_handlers.keys.join(', ')}"
          end
        end
      end
    end
  end
end
