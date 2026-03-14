# lex-cortex

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive wiring layer for the LegionIO agentic architecture. Cortex discovers loaded agentic extensions at runtime, builds phase handlers from their runners, and drives the tick cycle through `lex-tick`. It replaces standalone tick usage — when cortex is loaded, the tick actor disables itself and cortex's Think actor becomes the sole tick driver.

## Gem Info

- **Gem name**: `lex-cortex`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Cortex`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cortex/
  version.rb
  helpers/
    wiring.rb          # PHASE_MAP, PHASE_ARGS, resolve_runner_class, build_phase_handlers
    signal_buffer.rb   # Thread-safe signal queue (Mutex + Array, max 1000)
    runner_host.rb     # Wraps runner modules into instantiable objects with persistent state
  runners/
    cortex.rb          # think, ingest_signal, cortex_status, rewire
  actors/
    think.rb           # Every 1s actor driving the think loop
spec/
  legion/extensions/cortex/
    helpers/
      wiring_spec.rb
      signal_buffer_spec.rb
      runner_host_spec.rb
    runners/
      cortex_spec.rb
    client_spec.rb
  spec_helper.rb
```

## Key Concepts

### Phase Handler Wiring

`Helpers::Wiring::PHASE_MAP` maps each tick phase to an extension runner method. At startup, cortex discovers which extensions are loaded via `const_defined?` checks and builds a `phase_handlers` hash that `lex-tick`'s `execute_tick` consumes.

16 phases mapped (3 are nil/future):
- **Active tick**: sensory_processing, emotional_evaluation, memory_retrieval, identity_entropy_check, working_memory_integration, procedural_check, prediction_engine, mesh_interface, gut_instinct, action_selection, memory_consolidation
- **Dream cycle**: memory_audit, association_walk, contradiction_resolution, agenda_formation, consolidation_commit

### RunnerHost Pattern

Runner modules (like `Memory::Runners::Consolidation`) can't be instantiated directly — they're modules, not classes. `RunnerHost` is a plain object that `extend`s the module, giving it persistent instance state (`@default_store`, `@trust_map`, etc.) across ticks. One RunnerHost per unique extension+runner pair.

### Signal Buffer

Thread-safe `Mutex + Array` queue (max 1000 entries). External stimuli are pushed via `ingest_signal`, drained each tick by `think`. Signals are normalized with `received_at`, `salience`, and `source_type` defaults.

### Memoization with Retry

`runner_instances` is memoized for performance but cleared when `lex-tick` isn't found yet (race condition during extension loading). This allows cortex to retry discovery on the next tick rather than permanently failing.

## Runner Methods

All in `Runners::Cortex`:
- `think` — drain signal buffer, lazy-wire phase handlers, delegate to tick orchestrator
- `ingest_signal(signal:, source_type:, salience:)` — push external stimulus into buffer
- `cortex_status` — discovery info, wired phases, buffer depth
- `rewire` — clear memoized state, rediscover extensions, rebuild phase handlers

## Cortex vs Standalone Tick

| | Standalone Tick | Cortex |
|---|---|---|
| Actor | `Tick::Actor::Tick` (Every 1s) | `Cortex::Actor::Think` (Every 1s) |
| Phase handlers | Empty `{}` — all phases return `{ status: :no_handler }` | Wired from discovered extensions |
| Signal input | None (args: `{ signals: [] }`) | Signal buffer drained each tick |
| Enabled when | Cortex NOT loaded | Always (cortex is the default) |

The tick actor checks `!Legion::Extensions.const_defined?(:Cortex)` in `enabled?` and skips `initialize` (no timer created) when cortex is present.

## Integration Points

Cortex wires these extensions when available:
- **lex-tick**: Orchestrator (core dependency — cortex cannot function without it)
- **lex-emotion**: Valence evaluation + gut instinct
- **lex-memory**: Trace retrieval, decay cycle, Hebbian linking, tier migration
- **lex-identity**: Entropy anomaly detection
- **lex-coldstart**: Bootstrap progress check
- **lex-prediction**: Forward-model prediction
- **lex-mesh**: Agent mesh status
- **lex-consent**: Action consent check
- **lex-conflict**: Active conflict resolution

All are optional — missing extensions result in `{ status: :no_handler }` for their phases.

## Development Notes

- `PHASE_ARGS` lambdas build kwargs from cortex context (signals, prior_results, valences)
- `association_walk` extracts trace IDs from `memory_audit` prior results; returns `{ linked: false }` if no traces available
- Specs stub `Legion::Logging` since it won't be available in test
- `rubocop:disable` not needed — all methods are within configured limits

---

**Maintained By**: Matthew Iverson (@Esity)
