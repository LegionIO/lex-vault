# Changelog

## [0.2.0] - 2026-11-13

### Added
- `Vault::Auth` nested sub-extension: `Runners::Token#validate`, `Runners::UserPass#login` (LDAP), `Runners::AppRole#login` — auth-method token minting as first-class framework runners (own settings tree, AMQP prefix, meta-actors, MCP tools)
- Credential resolver (`Helpers::Auth#auth_resolve`): `token:` / `auth:` / settings precedence, single resolution point for every runner
- `Runners::Consul` and `Runners::Nomad` dynamic secrets engines
- `Errors`: `AuthUnresolved`, `APIError` (numeric code + Vault message, via the `Raiser` Faraday middleware), `ReadOnlyError`
- `read_only: true` guard on all write/mutating methods
- Ephemeral auth: `auth: { method:, ... }` opts mint a token for the call and toss it — no token state in the gem

### Changed (breaking)
- Runner return shapes: JSON bodies are returned directly with symbol keys (no `{ result: }` double-wrap); empty-body responses return `{ status: <int> }`; `Pki#ca_chain` (text PEM) wraps as `{ data: <body> }`
- Non-2xx Vault responses now raise `APIError` instead of returning the error body as data (`health`/`seal_status` exempt — their non-200 statuses are data)
- Unresolvable credentials raise `AuthUnresolved` instead of sending unauthenticated requests
- `KV#patch_secret` serializes the merge-patch body explicitly (Faraday's json middleware skips serialization when a non-JSON Content-Type is pre-set)
- Standalone `Client` seeds the resolver from constructor opts (`default_credentials` override); no longer overrides `connection`
- Nomad `read_role` corrected to GET `/role/{name}`; `generate_credential` corrected to POST `/cred/{accessor}` (the previous implementation never actually minted credentials)

### Notes
- Credentials are not yet redacted from logs/exception context — time-boxed to the end-to-end validation phase, tracked as the next follow-up
- The standalone `Client` does not mix in the dynamic engines or auth runners (shared method names would shadow); standalone auth uses the `auth:` descriptor

## [0.1.4] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.3] - 2026-03-22

### Changed
- Add runtime dependencies: legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport
- Update spec_helper with real sub-gem helper requires and Helpers::Lex stub

## [0.1.2] - 2026-03-21

### Added
- `Runners::Namespaces` with `list_namespaces`, `get_namespace`, `create_namespace`, `delete_namespace` for Vault Enterprise namespace CRUD

## [0.1.1] - 2026-03-18

### Changed
- deleted gemfile.lock, updated claude.md

## [0.1.0] - 2026-03-13

### Added
- Initial release
