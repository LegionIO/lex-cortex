# frozen_string_literal: true

# Stub the framework actor base class since legionio gem is not available in test
module Legion
  module Extensions
    module Actors
      class Every # rubocop:disable Lint/EmptyClass
      end
    end
  end
end

# Intercept the require in the actor file so it doesn't fail
$LOADED_FEATURES << 'legion/extensions/actors/every'

require 'legion/extensions/cortex/actors/think'

RSpec.describe Legion::Extensions::Cortex::Actor::Think do
  subject(:actor) { described_class.new }

  describe '#runner_class' do
    it 'returns the Cortex runner module' do
      expect(actor.runner_class).to eq(Legion::Extensions::Cortex::Runners::Cortex)
    end
  end

  describe '#runner_function' do
    it 'returns think' do
      expect(actor.runner_function).to eq('think')
    end
  end

  describe '#time' do
    it 'returns 1' do
      expect(actor.time).to eq(1)
    end
  end

  describe '#run_now?' do
    it 'returns true' do
      expect(actor.run_now?).to be true
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
