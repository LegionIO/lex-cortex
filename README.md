# lex-cortex

Cognitive wiring layer for the [LegionIO](https://github.com/LegionIO/LegionIO) agentic architecture. Discovers loaded agentic extensions at runtime, builds phase handlers from their runners, and drives the tick cycle through [lex-tick](https://github.com/LegionIO/lex-tick).

## Installation

Add to your Gemfile:

```ruby
gem 'lex-cortex'
```

## How It Works

Cortex sits between the tick orchestrator and all other agentic extensions. On each 1-second tick cycle it:

1. Drains the signal buffer (external stimuli pushed via `ingest_signal`)
2. Discovers which agentic extensions are loaded
3. Builds phase handlers that map tick phases to extension runner methods
4. Delegates to `lex-tick`'s `execute_tick` with the wired handlers

When cortex is loaded, the standalone tick actor automatically disables itself.

### Wired Phases

| Phase | Extension | Runner Method |
|-------|-----------|---------------|
| `emotional_evaluation` | lex-emotion | `evaluate_valence` |
| `memory_retrieval` | lex-memory | `retrieve_ranked` |
| `identity_entropy_check` | lex-identity | `check_entropy` |
| `procedural_check` | lex-coldstart | `coldstart_progress` |
| `prediction_engine` | lex-prediction | `predict` |
| `mesh_interface` | lex-mesh | `mesh_status` |
| `gut_instinct` | lex-emotion | `gut_instinct` |
| `action_selection` | lex-consent | `check_consent` |
| `memory_consolidation` | lex-memory | `decay_cycle` |
| `association_walk` | lex-memory | `hebbian_link` |
| `contradiction_resolution` | lex-conflict | `active_conflicts` |
| `consolidation_commit` | lex-memory | `migrate_tier` |

All extensions are optional. Missing extensions result in `{ status: :no_handler }` for their phases.

## Usage

Cortex runs automatically as a Legion extension. To interact with it programmatically:

```ruby
# Inject a signal
cortex.ingest_signal(signal: { event: 'user_message', text: 'hello' },
                     source_type: :human_direct,
                     salience: 0.8)

# Check status
cortex.cortex_status
# => { extensions_available: 8, wired_phases: 13, buffer_depth: 0, ... }

# Force rediscovery of extensions
cortex.rewire
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
