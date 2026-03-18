# lex-cortex

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive wiring layer for the LegionIO agentic architecture. Cortex discovers loaded agentic extensions at runtime, builds phase handlers from their runners, and drives the tick cycle through `lex-tick`. It replaces standalone tick usage — when cortex is loaded, the tick actor disables itself and cortex's Think actor becomes the sole tick driver.

## Gem Info

- **Gem name**: `lex-cortex`
- **Version**: `0.2.1`
- **Module**: `Legion::Extensions::Cortex`
- **Ruby**: `>= 3.4`
- **License**: MIT
- **Status**: DEPRECATED — functionality absorbed by `legion-gaia`. This gem is a thin delegation shim.

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

19 phases mapped:
- **Active tick** (12 phases): sensory_processing (`Attention:filter_signals`), emotional_evaluation (`Emotion:Valence:evaluate_valence`), memory_retrieval (`Memory:Traces:retrieve_and_reinforce`), identity_entropy_check (`Identity:Identity:check_entropy`), working_memory_integration (`Curiosity:detect_gaps`), procedural_check (`Coldstart:coldstart_progress`), prediction_engine (`Prediction:predict`), mesh_interface (`Mesh:mesh_status`), gut_instinct (`Emotion:Gut:gut_instinct`), action_selection (`Volition:form_intentions`), memory_consolidation (`Memory:Consolidation:decay_cycle`), post_tick_reflection (`Reflection:reflect`)
- **Dream cycle** (7 phases): memory_audit, association_walk, contradiction_resolution, agenda_formation (`Curiosity:form_agenda`), consolidation_commit, dream_reflection (`Reflection:reflect`), dream_narration (`Narrator:narrate`)

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
- **lex-attention**: Sensory signal filtering (`sensory_processing` phase)
- **lex-emotion**: Valence evaluation + gut instinct
- **lex-memory**: Trace retrieval+reinforce, decay cycle, Hebbian linking, tier migration
- **lex-identity**: Entropy anomaly detection
- **lex-curiosity**: Working memory integration + dream agenda formation
- **lex-coldstart**: Bootstrap progress check
- **lex-prediction**: Forward-model prediction
- **lex-mesh**: Agent mesh status
- **lex-volition**: Action intention formation (`action_selection` phase)
- **lex-reflection**: Post-tick and dream reflection (`post_tick_reflection`, `dream_reflection` phases)
- **lex-narrator**: Dream narration (`dream_narration` phase)
- **lex-conflict**: Dream contradiction resolution

All are optional — missing extensions result in `{ status: :no_handler }` for their phases.

## Development Notes

- `PHASE_ARGS` lambdas build kwargs from cortex context (signals, prior_results, valences)
- `association_walk` extracts trace IDs from `memory_audit` prior results; returns `{ linked: false }` if no traces available
- Specs stub `Legion::Logging` since it won't be available in test
- `rubocop:disable` not needed — all methods are within configured limits

---

**Maintained By**: Matthew Iverson (@Esity)
