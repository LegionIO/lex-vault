# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault::Auth do
  it 'is a module' do
    expect(described_class).to be_a(Module)
  end

  describe '.default_settings' do
    it 'declares a runner desc for each auth method' do
      expect(described_class.default_settings[:runners]).to eq(
        token:     { desc: 'Validate a Vault token' },
        user_pass: { desc: 'LDAP login (username/password)' },
        app_role:  { desc: 'AppRole login (role_id/secret_id)' }
      )
    end

    it 'declares no connection credentials (those live on the root Vault tree)' do
      expect(described_class.default_settings.keys).to eq([:runners])
    end
  end
end
