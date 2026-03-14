# lex-vault

HashiCorp Vault integration for [LegionIO](https://github.com/LegionIO/LegionIO). Provides runners for interacting with the Vault HTTP API covering system operations, KV v2 secrets, token auth, Transit encryption, PKI certificates, and lease management.

## Installation

```bash
gem install lex-vault
```

## Functions

### System
`health`, `seal_status`, `seal`, `unseal`, `init`, `list_mounts`, `mount`, `unmount`, `list_auth`, `enable_auth`, `disable_auth`, `list_policies`, `get_policy`, `put_policy`, `delete_policy`

### KV (v2 Secrets)
`read_secret`, `write_secret`, `patch_secret`, `delete_secret`, `delete_versions`, `undelete_versions`, `destroy_versions`, `list_secrets`, `read_metadata`, `write_metadata`, `delete_metadata`

### Token
`create_token`, `lookup_token`, `lookup_self`, `renew_token`, `renew_self`, `revoke_token`, `revoke_self`, `list_accessors`, `list_token_roles`, `get_token_role`, `create_token_role`, `delete_token_role`

### Transit
`create_key`, `read_key`, `list_keys`, `delete_key`, `rotate_key`, `encrypt`, `decrypt`, `rewrap`, `datakey`, `sign`, `verify`, `hash_data`, `random_bytes`

### PKI
`issue`, `sign_csr`, `revoke`, `list_certs`, `get_cert`, `ca_chain`, `list_pki_roles`, `get_pki_role`, `create_pki_role`, `tidy`

### Leases
`lookup_lease`, `renew_lease`, `revoke_lease`, `list_leases`

## Standalone Usage

```ruby
require 'legion/extensions/vault'

client = Legion::Extensions::Vault::Client.new(
  address: 'https://vault.example.com',
  token: 'hvs.your-token',
  namespace: 'admin/team1' # optional, Enterprise only
)

# Read a secret
client.read_secret(path: 'myapp/config')

# Write a secret
client.write_secret(path: 'myapp/config', data: { api_key: 'secret123' })

# Encrypt with Transit
client.encrypt(name: 'my-key', plaintext: Base64.strict_encode64('hello'))

# Issue a PKI certificate
client.issue(role: 'web-server', common_name: 'app.example.com')
```

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (optional for standalone client usage)
- HashiCorp Vault server (any version with HTTP API v1)
- `faraday` >= 2.0

## License

MIT
