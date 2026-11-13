# lex-vault

Legion Extension connecting LegionIO to HashiCorp Vault. Provides runners for system operations, KV v2 secrets, token auth management, Transit encryption, PKI certificates, lease management, dynamic secrets (Consul, Nomad), Enterprise namespace management, and auth-method token minting (LDAP, AppRole).

## Architecture

```
Legion::Extensions::Vault
├── Errors/               # AuthUnresolved, APIError (code+message), ReadOnlyError, Raiser (Faraday middleware)
├── Helpers/
│   ├── Client            # build_connection (Faraday) + connection (pipe entry) + vault_normalize
│   └── Auth              # auth_resolve — the credential resolver (opts pipe policy)
├── Runners/              # engines, flat
│   ├── System            # health/seal-status (Raiser bypass: non-200 is data), seal/unseal, mounts, auth, policies
│   ├── Kv                # KV v2: read/write/patch/delete secrets + versions + metadata
│   ├── Token             # token auth engine management: create/lookup/renew/revoke + roles
│   ├── Transit           # encrypt/decrypt/rewrap/datakey/sign/verify/hash/random + keys
│   ├── Pki               # issue/sign/revoke certs, CA chain (text → { data: }), roles, tidy
│   ├── Leases            # lookup/renew/revoke leases
│   ├── Namespaces        # Vault Enterprise namespace CRUD
│   ├── Consul            # dynamic secrets: config/access, role CRUD, generate_credential
│   └── Nomad             # dynamic secrets: config access/lease, role CRUD, POST /cred/{accessor}
├── Auth/                 # nested sub-extension (own settings tree, AMQP prefix, meta-actors)
│   ├── Helpers/Login     # vault_login — shared mint (never attaches a token)
│   └── Runners/
│       ├── Token         # validate (lookup) — not a mint
│       ├── UserPass      # LDAP login
│       └── AppRole       # AppRole login
└── Client                # standalone client (core engines only; auth via the auth: descriptor)
```

## Key Design Decisions

- **The opts pipe.** Credential opts (`token:`, `address:`, `namespace:`, `auth: { method:, ... }`) flow through every runner's trailing `**` and are resolved in exactly one place: `Helpers::Auth#auth_resolve`. Precedence: explicit `token:` > `auth:` descriptor > settings (`extensions.vault`). Runners never touch credential keys; `connection(**)` is the only pipe entry.
- **Ephemeral minting.** An `auth:` descriptor mints a token via the matching `Vault::Auth` runner (direct module call, not through the tasker), uses it for the call, and tosses it. No token state, caching, or renewal lives in this gem — node-identity token lifecycle is legion-crypt's job.
- **Fail loud, named.** No resolvable credentials → `AuthUnresolved`; non-2xx Vault responses → `APIError` (via the `Raiser` Faraday middleware); write with `read_only: true` → `ReadOnlyError`. A raised named error is the framework's known-outcome path (`task.exception`) — runner code has no rescue blocks.
- **Returns.** JSON-body responses return the normalized body directly (symbol keys via `vault_normalize`); empty-body (204) responses return `{ status: <int> }`; the plain-text PEM endpoint (`Pki#ca_chain`) wraps as `{ data: <body> }`. No `{ result: }` double-wrap.
- **health/seal-status bypass the Raiser** (`raise_errors: false`) — their non-200 statuses (sealed, standby, uninit) are data.
- **Client is core engines only.** The dynamic engines (Consul/Nomad) and auth runners are NOT mixed into `Client` — they share generic method names (`create_role`, `login`, ...) that would shadow each other. Standalone auth: `Client.new(auth: { method: :user_pass, username:, password: })`.
- **Consul's business token is `consul_token:`** — never the pipe's `token:` (that's the Vault credential).
- **Nomad corrections vs. the original internal implementation:** `read_role` is GET `/role/{name}` (was POST); `generate_credential` is POST `/cred/{accessor}` (was GET of the role path — it never minted).
- Depends on `faraday`. All API calls go through `/v1/`.
- Known limitation (time-boxed): credentials are NOT redacted from logs/exception context yet — plain text until end-to-end validation with a daemon is complete. Tracked as the next follow-up.
