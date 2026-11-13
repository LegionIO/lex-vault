# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault do
  it 'is a module' do
    expect(described_class).to be_a(Module)
  end

  it 'defines the Client class' do
    expect(Legion::Extensions::Vault::Client).to be_a(Class)
  end

  describe '.default_settings' do
    subject(:settings) { described_class.default_settings }

    it 'declares the connection defaults' do
      expect(settings[:address]).to eq('http://127.0.0.1:8200')
      expect(settings[:token]).to be_nil
      expect(settings[:namespace]).to be_nil
    end

    it 'declares a runner desc for each core engine' do
      expect(settings[:runners].keys).to contain_exactly(:kv, :token, :transit, :pki, :leases, :namespaces, :system)
      expect(settings[:runners].values.all? { |entry| entry[:desc].is_a?(String) }).to be(true)
    end
  end
end
