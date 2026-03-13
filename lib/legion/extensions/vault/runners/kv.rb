# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Kv
          include Legion::Extensions::Vault::Helpers::Client

          def read_secret(path:, mount: 'secret', version: nil, **)
            url = "/v1/#{mount}/data/#{path}"
            params = version ? { version: version } : {}
            response = connection(**).get(url, params)
            { result: response.body }
          end

          def write_secret(path:, data:, mount: 'secret', cas: nil, **)
            url = "/v1/#{mount}/data/#{path}"
            body = { data: data }
            body[:options] = { cas: cas } if cas
            response = connection(**).post(url, body)
            { result: response.body }
          end

          def patch_secret(path:, data:, mount: 'secret', **)
            url = "/v1/#{mount}/data/#{path}"
            conn = connection(**)
            conn.headers['Content-Type'] = 'application/merge-patch+json'
            response = conn.patch(url, { data: data })
            { result: response.body }
          end

          def delete_secret(path:, mount: 'secret', **)
            response = connection(**).delete("/v1/#{mount}/data/#{path}")
            { result: response.status == 204 }
          end

          def delete_versions(path:, versions:, mount: 'secret', **)
            response = connection(**).post("/v1/#{mount}/delete/#{path}", { versions: versions })
            { result: response.status == 204 }
          end

          def undelete_versions(path:, versions:, mount: 'secret', **)
            response = connection(**).post("/v1/#{mount}/undelete/#{path}", { versions: versions })
            { result: response.status == 204 }
          end

          def destroy_versions(path:, versions:, mount: 'secret', **)
            response = connection(**).put("/v1/#{mount}/destroy/#{path}", { versions: versions })
            { result: response.status == 204 }
          end

          def list_secrets(path:, mount: 'secret', **)
            response = connection(**).get("/v1/#{mount}/metadata/#{path}", { list: true })
            { result: response.body }
          end

          def read_metadata(path:, mount: 'secret', **)
            response = connection(**).get("/v1/#{mount}/metadata/#{path}")
            { result: response.body }
          end

          def write_metadata(path:, mount: 'secret', max_versions: nil, cas_required: nil, delete_version_after: nil, **)
            body = { max_versions: max_versions, cas_required: cas_required,
                     delete_version_after: delete_version_after }.compact
            response = connection(**).post("/v1/#{mount}/metadata/#{path}", body)
            { result: response.status == 204 }
          end

          def delete_metadata(path:, mount: 'secret', **)
            response = connection(**).delete("/v1/#{mount}/metadata/#{path}")
            { result: response.status == 204 }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end
