# frozen_string_literal: true

RSpec.describe Legion::Extensions::Cortex::Runners::Cortex do
  let(:host_class) do
    Class.new do
      include Legion::Extensions::Cortex::Runners::Cortex
    end
  end
  let(:host) { host_class.new }

  describe '#ingest_signal' do
    it 'adds a signal to the buffer' do
      result = host.ingest_signal(signal: { value: 'test' }, source_type: :human_direct, salience: 0.8)
      expect(result[:ingested]).to be true
      expect(result[:buffer_depth]).to eq(1)
    end

    it 'accepts multiple signals' do
      host.ingest_signal(signal: { a: 1 })
      host.ingest_signal(signal: { b: 2 })
      result = host.ingest_signal(signal: { c: 3 })
      expect(result[:buffer_depth]).to eq(3)
    end
  end

  describe '#cortex_status' do
    it 'returns discovery information' do
      status = host.cortex_status
      expect(status).to have_key(:extensions_available)
      expect(status).to have_key(:extensions_total)
      expect(status).to have_key(:wired_phases)
      expect(status).to have_key(:buffer_depth)
      expect(status).to have_key(:discovery)
    end
  end

  describe '#think' do
    context 'without lex-tick available' do
      it 'returns an error' do
        result = host.think
        expect(result[:error]).to eq(:no_tick_extension)
      end
    end
  end

  describe '#rewire' do
    it 'rebuilds phase handlers' do
      result = host.rewire
      expect(result[:rewired]).to be true
      expect(result).to have_key(:wired_phases)
      expect(result).to have_key(:phase_list)
    end
  end
end
