# lex-vault

HashiCorp Vault integration for [LegionIO](https://github.com/LegionIO/LegionIO). Provides runners for the Vault HTTP API: system operations, KV v2 secrets, token auth management, Transit encryption, PKI certificates, lease management, dynamic secrets engines (Consul, Nomad), Enterprise namespaces, and auth-method token minting (LDAP, AppRole).

## Installation

```bash
gem install lex-vault
```

## Credentials

Every runner method accepts the same optional credential opts (they flow through the
method's trailing `**` and are resolved in one place):

| Opt | Meaning |
|-----|---------|
| `token:` | Use this Vault token for the call. |
| `address:` | Vault base URL (overrides the configured address). |
| `namespace:` | Enterprise namespace for the call. |
| `auth:` | `{ method: :user_pass, username:, password: }` or `{ method: :app_role, role_id:, secret_id: }` — mints a token for this call (ephemeral: used once, tossed). |

Precedence: `token:` > `auth:` > configured settings
(`Legion::Settings[:extensions][:vault]`: `address`, `token`, `namespace`).
No resolvable credentials raise `Legion::Extensions::Vault::Errors::AuthUnresolved`.

Non-2xx Vault responses raise `Legion::Extensions::Vault::Errors::APIError`
(carries the numeric `code` and Vault's message). Write methods accept
`read_only: true`, which raises `ReadOnlyError` instead of executing.

## Functions

### System
`health`, `seal_status`, `seal`, `unseal`, `init`, `list_mounts`, `mount`, `unmount`, `list_auth`, `enable_auth`, `disable_auth`, `list_policies`, `get_policy`, `put_policy`, `delete_policy`

(`health`/`seal_status` return their non-200 statuses as data — sealed/standby/uninitialized are conditions, not errors.)

### KV (v2 Secrets)
`read_secret`, `write_secret`, `patch_secret`, `delete_secret`, `delete_versions`, `undelete_versions`, `destroy_versions`, `list_secrets`, `read_metadata`, `write_metadata`, `delete_metadata`

### Token (auth engine management)
`create_token`, `lookup_token`, `lookup_self`, `renew_token`, `renew_self`, `revoke_token`, `revoke_self`, `list_accessors`, `list_token_roles`, `get_token_role`, `create_token_role`, `delete_token_role`

### Transit
`create_key`, `read_key`, `list_keys`, `delete_key`, `rotate_key`, `encrypt`, `decrypt`, `rewrap`, `datakey`, `sign`, `verify`, `hash_data`, `random_bytes`

### PKI
`issue`, `sign_csr`, `revoke`, `list_certs`, `get_cert`, `ca_chain`, `list_pki_roles`, `get_pki_role`, `create_pki_role`, `tidy`

### Leases
`lookup_lease`, `renew_lease`, `revoke_lease`, `list_leases`

### Namespaces (Vault Enterprise)
`list_namespaces`, `get_namespace`, `create_namespace`, `delete_namespace`

### Consul (dynamic secrets)
`configure` (the Consul server's own token is `consul_token:`, not the Vault `token:`), `create_role`, `read_role`, `list_roles`, `delete_role`, `generate_credential`

### Nomad (dynamic secrets)
`create_role`, `read_role`, `list_roles`, `delete_role`, `generate_credential(accessor:)` (POST `/v1/nomad/cred/{accessor}`), `configure_access`, `read_config_access`, `configure_lease`, `read_lease`, `delete_lease`

### Auth (token minting)
`validate(token:)` — look up a token's properties. `login(username:, password:, mount: 'ldap')` — LDAP. `login(role_id:, secret_id:, mount: 'approle')` — AppRole. All return Vault's standard login envelope (`auth: { client_token:, lease_id:, ... }`).

## Returns

- JSON-body responses: the normalized body, **symbol keys**, no wrapping
  (`read_secret` → `{ data: { data: {...}, metadata: {...} } }`).
- Empty-body (204) responses: `{ status: 204 }`.
- `Pki#ca_chain` (plain-text PEM): `{ data: "-----BEGIN CERTIFICATE-----..." }`.

## Framework Usage

```ruby
# Any task/chain/CLI — credentials from settings or call-time opts
Legion::Runner.run(
  runner_class: 'Legion::Extensions::Vault::Runners::Kv',
  function: 'read_secret',
  args: { path: 'myapp/config', token: 'hvs.your-token' }
)

# Mint via LDAP for a single call (ephemeral)
client.read_secret(path: 'myapp/config',
                   auth: { method: :user_pass, username: 'svc', password: '...' })
```

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

# Or mint via the descriptor instead of holding a token
client = Legion::Extensions::Vault::Client.new(
  address: 'https://vault.example.com',
  auth: { method: :app_role, role_id: 'r.id', secret_id: 's.id' }
)
```

The standalone `Client` covers the core engines. The dynamic engines (Consul/Nomad)
and auth runners are framework-level units — they share generic method names
(`create_role`, `login`) that would shadow each other in one class.

## Known limitation (time-boxed)

Credentials are not yet redacted from logs and exception context — they appear in
plain text. This is intentional during the end-to-end validation phase and is the
tracked follow-up for the next release.

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (optional for standalone client usage)
- HashiCorp Vault server (any version with HTTP API v1)
- `faraday` >= 2.0

## License

MIT
