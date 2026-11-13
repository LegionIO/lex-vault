# frozen_string_literal: true

require 'legion/json'
require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Kv
          include Legion::Extensions::Vault::Helpers::Client

          def read_secret(path:, mount: 'secret', version: nil, **)
            params = version ? { version: version } : {}
            vault_normalize(connection(**).get("/v1/#{mount}/data/#{path}", params).body)
          end

          def write_secret(path:, data:, mount: 'secret', cas: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { data: data }
            body[:options] = { cas: cas } if cas
            vault_normalize(connection(**).post("/v1/#{mount}/data/#{path}", body).body)
          end

          def patch_secret(path:, data:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            conn = connection(**)
            conn.headers['Content-Type'] = 'application/merge-patch+json'
            # Explicit serialize: with a non-json Content-Type pre-set,
            # Faraday's json middleware skips body serialization.
            response = conn.patch("/v1/#{mount}/data/#{path}", json_dump({ data: data }))
            vault_normalize(response.body)
          end

          def delete_secret(path:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/data/#{path}").status }
          end

          def delete_versions(path:, versions:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post("/v1/#{mount}/delete/#{path}", { versions: versions }).status }
          end

          def undelete_versions(path:, versions:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post("/v1/#{mount}/undelete/#{path}", { versions: versions }).status }
          end

          def destroy_versions(path:, versions:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).put("/v1/#{mount}/destroy/#{path}", { versions: versions }).status }
          end

          def list_secrets(path:, mount: 'secret', **)
            vault_normalize(connection(**).get("/v1/#{mount}/metadata/#{path}", { list: true }).body)
          end

          def read_metadata(path:, mount: 'secret', **)
            vault_normalize(connection(**).get("/v1/#{mount}/metadata/#{path}").body)
          end

          def write_metadata(path:, max_versions: nil, cas_required: nil, delete_version_after: nil,
                             mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { max_versions: max_versions, cas_required: cas_required,
                     delete_version_after: delete_version_after }.compact
            { status: connection(**).post("/v1/#{mount}/metadata/#{path}", body).status }
          end

          def delete_metadata(path:, mount: 'secret', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/metadata/#{path}").status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
