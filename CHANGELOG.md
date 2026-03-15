# Changelog

## [0.2.0] - 2026-03-15

### Changed
- All runner methods delegate to `Legion::Gaia` when available (deprecation shim)
- Think actor skips execution when GAIA heartbeat is active (`run_now?` returns `false`)
- Deprecation warnings emitted on all delegated calls

### Deprecated
- This extension is deprecated in favor of `legion-gaia`. All functionality has been absorbed into the GAIA cognitive coordination layer.

## [0.1.1] - 2026-03-15

### Added
- `spec/legion/extensions/cortex/actors/think_spec.rb` (7 examples) — tests for the Think actor (Every 1s)
- `spec/legion/extensions/cortex/integration/cortex_tick_spec.rb` (12 examples) — integration tests for the cortex→tick critical path: real RunnerHost wiring, signal ingestion, mode transitions, phase handler invocation, budget enforcement, and rewire

## [0.1.0] - 2026-03-13

### Added
- Initial release
