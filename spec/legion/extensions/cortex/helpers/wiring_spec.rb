# frozen_string_literal: true

RSpec.describe Legion::Extensions::Cortex::Helpers::Wiring do
  describe 'PHASE_MAP' do
    it 'is a frozen hash' do
      expect(described_class::PHASE_MAP).to be_frozen
    end

    it 'contains all 11 active tick phases' do
      active_phases = %i[sensory_processing emotional_evaluation memory_retrieval
                         identity_entropy_check working_memory_integration procedural_check
                         prediction_engine mesh_interface gut_instinct action_selection
                         memory_consolidation]
      active_phases.each do |phase|
        expect(described_class::PHASE_MAP).to have_key(phase)
      end
    end

    it 'contains dream cycle phases' do
      dream_phases = %i[memory_audit association_walk contradiction_resolution
                        agenda_formation consolidation_commit]
      dream_phases.each do |phase|
        expect(described_class::PHASE_MAP).to have_key(phase)
      end
    end
  end

  describe '.resolve_runner_class' do
    it 'returns nil for missing extensions' do
      expect(described_class.resolve_runner_class(:Nonexistent, :Foo)).to be_nil
    end

    it 'returns the runner module when available' do
      # Cortex itself is always available in test
      result = described_class.resolve_runner_class(:Cortex, :Cortex)
      expect(result).to eq(Legion::Extensions::Cortex::Runners::Cortex)
    end
  end

  describe '.discover_available_extensions' do
    it 'returns a hash of extension availability' do
      discovery = described_class.discover_available_extensions
      expect(discovery).to be_a(Hash)
      expect(discovery.values.first).to have_key(:loaded)
    end
  end

  describe '.collect_valences' do
    it 'returns empty array for nil' do
      expect(described_class.collect_valences(nil)).to eq([])
    end

    it 'returns empty array when no emotional_evaluation' do
      expect(described_class.collect_valences({})).to eq([])
    end

    it 'extracts valence from emotional_evaluation result' do
      valence = { urgency: 0.5, importance: 0.3, novelty: 0.2, familiarity: 0.8 }
      results = { emotional_evaluation: { valence: valence } }
      expect(described_class.collect_valences(results)).to eq([valence])
    end
  end
end
