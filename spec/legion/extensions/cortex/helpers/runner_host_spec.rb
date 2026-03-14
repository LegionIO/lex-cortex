# frozen_string_literal: true

RSpec.describe Legion::Extensions::Cortex::Helpers::RunnerHost do
  let(:test_module) do
    Module.new do
      def test_method
        { result: :ok }
      end
    end
  end

  subject(:host) { described_class.new(test_module) }

  it 'extends the host with the runner module' do
    expect(host).to respond_to(:test_method)
  end

  it 'calls methods on the runner module' do
    expect(host.test_method).to eq({ result: :ok })
  end

  it 'has a readable to_s' do
    expect(host.to_s).to include('RunnerHost')
  end

  it 'has a readable inspect' do
    expect(host.inspect).to include('RunnerHost')
  end
end
