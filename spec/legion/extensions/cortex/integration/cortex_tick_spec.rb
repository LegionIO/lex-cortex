# frozen_string_literal: true

# Integration spec: cortex → tick wiring
#
# Requires tick files directly by path since lex-tick is not a gem dependency
# of lex-cortex. The spec exercises the full critical path:
#   Cortex#think → RunnerHost(Tick::Orchestrator)#execute_tick → phase handlers
#
tick_lib = '/Users/miverso2/rubymine/legion/extensions-agentic/lex-tick/lib'
require "#{tick_lib}/legion/extensions/tick/helpers/constants"
require "#{tick_lib}/legion/extensions/tick/helpers/state"
require "#{tick_lib}/legion/extensions/tick/runners/orchestrator"

RSpec.describe 'Cortex → Tick integration' do
  # Remove the Tick constant after all integration examples complete so that
  # unit specs (e.g. runners/cortex_spec.rb "without lex-tick available") are
  # not affected by tick being loaded into the process.
  after(:all) do
    Legion::Extensions.send(:remove_const, :Tick) if Legion::Extensions.const_defined?(:Tick)
  end

  # Stub Legion::Logging before each example (stub_const must be per-test).
  before do
    stub_const('Legion::Logging', Module.new do
      def self.debug(_msg); end
      def self.info(_msg);  end
      def self.warn(_msg);  end
      def self.error(_msg); end
    end)
  end

  # Build a fresh cortex host (includes the Cortex runner module) each example.
  let(:host_class) do
    Class.new { include Legion::Extensions::Cortex::Runners::Cortex }
  end
  let(:host) { host_class.new }

  # A real RunnerHost wrapping the real Tick::Runners::Orchestrator module.
  let(:tick_module) { Legion::Extensions::Tick::Runners::Orchestrator }
  let(:tick_host)   { Legion::Extensions::Cortex::Helpers::RunnerHost.new(tick_module) }

  # Minimal phase handler – returns a well-formed result hash.
  let(:ok_handler) { ->(**) { { status: :ok, value: :test } } }

  # Phase handlers for sentinel mode (5 phases).
  let(:sentinel_handlers) do
    %i[sensory_processing emotional_evaluation memory_retrieval
       prediction_engine memory_consolidation].to_h { |phase| [phase, ok_handler] }
  end

  # Phase handlers for full_active mode (all 12 phases).
  let(:full_active_handlers) do
    Legion::Extensions::Tick::Helpers::Constants::PHASES
      .to_h { |phase| [phase, ok_handler] }
  end

  # Inject pre-built runner_instances and phase_handlers directly onto the host,
  # bypassing the real Wiring discovery (which needs loaded extensions).
  def stub_wiring(host, tick_host, phase_handlers)
    host.instance_variable_set(:@runner_instances, { Tick_Orchestrator: tick_host })
    host.instance_variable_set(:@phase_handlers, phase_handlers)
  end

  # ── Scenario 1: Basic think cycle completes ─────────────────────────────────

  describe 'basic think cycle' do
    it 'returns a result hash with the expected keys' do
      stub_wiring(host, tick_host, sentinel_handlers)

      result = host.think

      expect(result).to be_a(Hash)
      expect(result).to have_key(:tick_number)
      expect(result).to have_key(:mode)
      expect(result).to have_key(:phases_executed)
      expect(result).to have_key(:results)
    end

    it 'increments the tick number on each call' do
      stub_wiring(host, tick_host, sentinel_handlers)

      first  = host.think
      second = host.think

      expect(second[:tick_number]).to eq(first[:tick_number] + 1)
    end
  end

  # ── Scenario 2: Signal ingestion flows through to tick ──────────────────────

  describe 'signal ingestion' do
    it 'drains the buffer after think' do
      stub_wiring(host, tick_host, sentinel_handlers)

      host.ingest_signal(signal: { value: 'ping' }, source_type: :ambient, salience: 0.1)
      expect(host.send(:signal_buffer).size).to eq(1)

      host.think

      expect(host.send(:signal_buffer).size).to eq(0)
    end

    it 'passes signals to tick and tick records the signal timestamp' do
      stub_wiring(host, tick_host, sentinel_handlers)

      host.ingest_signal(signal: { value: 'alert' }, source_type: :ambient, salience: 0.5)
      result = host.think

      state = tick_host.instance_variable_get(:@tick_state)
      expect(state.last_signal_at).not_to be_nil
      expect(result[:phases_executed]).not_to be_empty
    end
  end

  # ── Scenario 3: Mode transitions under signal pressure ──────────────────────

  describe 'mode transitions under signal pressure' do
    it 'transitions dormant → sentinel when any signal arrives' do
      # Fresh tick host starts in :dormant; wire dormant handler only.
      stub_wiring(host, tick_host, { memory_consolidation: ok_handler })

      state = tick_host.instance_variable_get(:@tick_state) ||
              Legion::Extensions::Tick::Helpers::State.new
      expect(state.mode).to eq(:dormant)

      host.ingest_signal(signal: { value: 'wake' }, source_type: :ambient, salience: 0.1)
      result = host.think

      expect(result[:mode]).to eq(:sentinel)
    end

    it 'transitions sentinel → full_active on human_direct signal' do
      tick_host.instance_variable_set(
        :@tick_state,
        Legion::Extensions::Tick::Helpers::State.new(mode: :sentinel)
      )
      stub_wiring(host, tick_host, full_active_handlers)

      host.ingest_signal(signal: { value: 'hello' }, source_type: :human_direct, salience: 0.9)
      result = host.think

      expect(result[:mode]).to eq(:full_active)
    end

    it 'transitions sentinel → full_active on high-salience signal alone' do
      tick_host.instance_variable_set(
        :@tick_state,
        Legion::Extensions::Tick::Helpers::State.new(mode: :sentinel)
      )
      stub_wiring(host, tick_host, full_active_handlers)

      host.ingest_signal(
        signal:      { alert: true },
        source_type: :system,
        salience:    Legion::Extensions::Tick::Helpers::Constants::HIGH_SALIENCE_THRESHOLD
      )
      result = host.think

      expect(result[:mode]).to eq(:full_active)
    end
  end

  # ── Scenario 4: Phase handlers are called during tick ───────────────────────

  describe 'phase handler invocation' do
    # Use a tick state pre-wired to sentinel with a recent signal so no idle
    # time-based transition fires during the test.
    let(:sentinel_state) do
      state = Legion::Extensions::Tick::Helpers::State.new(mode: :sentinel)
      state.record_signal(salience: 0.1)
      state
    end

    it 'calls the wired phase handler and receives state and signals' do
      call_log = []
      spy_handler = lambda do |state:, signals:, prior_results:|
        call_log << { state: state, signals: signals, prior_results: prior_results }
        { status: :ok, spy: true }
      end

      tick_host.instance_variable_set(:@tick_state, sentinel_state)
      handlers = sentinel_handlers.merge(sensory_processing: spy_handler)
      stub_wiring(host, tick_host, handlers)

      host.think

      expect(call_log).not_to be_empty
      expect(call_log.first[:signals]).to be_an(Array)
      expect(call_log.first[:state]).to be_a(Legion::Extensions::Tick::Helpers::State)
    end

    it 'provides prior_results from earlier phases to later phase handlers' do
      received_prior = nil
      late_handler = lambda do |**kwargs|
        received_prior = kwargs[:prior_results]
        { status: :ok }
      end

      # memory_consolidation is the last sentinel phase; earlier phases populate prior_results.
      tick_host.instance_variable_set(:@tick_state, sentinel_state)
      handlers = sentinel_handlers.merge(memory_consolidation: late_handler)
      stub_wiring(host, tick_host, handlers)

      host.think

      expect(received_prior).to be_a(Hash)
      expect(received_prior.keys).to include(:sensory_processing)
    end
  end

  # ── Scenario 5: Budget enforcement skips phases ──────────────────────────────

  describe 'budget enforcement' do
    it 'skips remaining sentinel phases when the first phase exhausts the budget' do
      # Keep tick in sentinel mode with a low-salience signal so no promotion occurs.
      tick_host.instance_variable_set(
        :@tick_state,
        Legion::Extensions::Tick::Helpers::State.new(mode: :sentinel)
      )

      # Slow handler sleeps longer than SENTINEL_TICK_BUDGET (0.5s)
      budget = Legion::Extensions::Tick::Helpers::Constants::SENTINEL_TICK_BUDGET
      slow_handler = lambda do |**|
        sleep(budget * 1.1)
        { status: :ok }
      end

      handlers = sentinel_handlers.merge(sensory_processing: slow_handler)
      stub_wiring(host, tick_host, handlers)

      # Low-salience signal keeps mode at sentinel (not promoted to full_active)
      host.ingest_signal(signal: { x: 1 }, source_type: :ambient, salience: 0.1)
      result = host.think

      # After mode transition from sentinel with a signal, tick stays sentinel.
      # The slow first phase exceeds the 0.5s budget → remaining phases are skipped.
      expect(result[:phases_skipped]).not_to be_empty
    end
  end

  # ── Scenario 6: Rewire clears state and rediscovers ─────────────────────────

  describe 'rewire' do
    it 'clears memoized runner_instances and phase_handlers then rebuilds' do
      stub_wiring(host, tick_host, sentinel_handlers)

      expect(host.instance_variable_get(:@runner_instances)).not_to be_nil
      expect(host.instance_variable_get(:@phase_handlers)).not_to be_nil

      # Stub Wiring so rewire completes without needing real extensions loaded
      allow(Legion::Extensions::Cortex::Helpers::Wiring)
        .to receive(:resolve_runner_class).and_return(nil)
      allow(Legion::Extensions::Cortex::Helpers::Wiring)
        .to receive(:build_phase_handlers).and_return({})

      result = host.rewire

      expect(result[:rewired]).to be true
      expect(host.instance_variable_get(:@phase_handlers)).to eq({})
    end

    it 'rebuilds phase handlers from the new discovery result' do
      stub_wiring(host, tick_host, sentinel_handlers)

      new_handlers = { memory_consolidation: ok_handler }
      allow(Legion::Extensions::Cortex::Helpers::Wiring)
        .to receive(:resolve_runner_class)
        .with(:Tick, :Orchestrator)
        .and_return(tick_module)
      allow(Legion::Extensions::Cortex::Helpers::Wiring)
        .to receive(:resolve_runner_class)
        .with(anything, anything)
        .and_return(nil)
      allow(Legion::Extensions::Cortex::Helpers::Wiring)
        .to receive(:build_phase_handlers)
        .and_return(new_handlers)

      result = host.rewire

      expect(result[:rewired]).to be true
      expect(result[:phase_list]).to eq(new_handlers.keys)
    end
  end
end
