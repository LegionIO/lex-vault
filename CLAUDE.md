# lex-vault: HashiCorp Vault Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent (Level 2)**: `/Users/miverso2/rubymine/legion/extensions/CLAUDE.md`
- **Parent (Level 1)**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to HashiCorp Vault. Provides runners for system operations, KV v2 secrets, token auth, Transit encryption, PKI certificates, and lease management.

**GitHub**: https://github.com/LegionIO/lex-vault
**License**: MIT
**Version**: 0.1.1

## Architecture

```
Legion::Extensions::Vault
├── Runners/
│   ├── System            # Health, seal/unseal, mounts, auth, policies
│   ├── Kv                # KV v2: read/write/delete/list secrets + metadata
│   ├── Token             # Token auth: create/lookup/renew/revoke + roles
│   ├── Transit           # Encrypt/decrypt/sign/verify/hash/random
│   ├── Pki               # Issue/sign/revoke certs, CA chain, roles
│   └── Leases            # Lookup/renew/revoke leases
├── Helpers/
│   └── Client            # Faraday connection builder (X-Vault-Token + namespace)
└── Client                # Standalone client class (includes all runners)
```

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` | HTTP client for Vault REST API |

## Connection

The client accepts `address` (matching Vault's `VAULT_ADDR`), `token`, and optional `namespace` (Enterprise). All API calls go through `/v1/` prefix.

## Testing

44 specs across 8 spec files.

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
