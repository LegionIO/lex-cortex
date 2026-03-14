# frozen_string_literal: true

RSpec.describe Legion::Extensions::Cortex do
  it 'has a version number' do
    expect(Legion::Extensions::Cortex::VERSION).not_to be_nil
  end

  it 'has a version string' do
    expect(Legion::Extensions::Cortex::VERSION).to eq('0.1.0')
  end
end
