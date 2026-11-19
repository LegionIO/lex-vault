# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Transit
          include Legion::Extensions::Vault::Helpers::Client

          def create_key(name:, mount: 'transit', type: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = type ? { type: type } : {}
            { status: connection(**).post("/v1/#{mount}/keys/#{name}", body).status }
          end

          def read_key(name:, mount: 'transit', **)
            vault_normalize(connection(**).get("/v1/#{mount}/keys/#{name}").body)
          end

          def list_keys(mount: 'transit', **)
            vault_normalize(connection(**).get("/v1/#{mount}/keys", { list: true }).body)
          end

          def delete_key(name:, mount: 'transit', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/keys/#{name}").status }
          end

          def rotate_key(name:, mount: 'transit', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post("/v1/#{mount}/keys/#{name}/rotate").status }
          end

          def encrypt(name:, plaintext:, mount: 'transit', context: nil, **)
            body = { plaintext: plaintext, context: context }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/encrypt/#{name}", body).body)
          end

          def decrypt(name:, ciphertext:, mount: 'transit', context: nil, **)
            body = { ciphertext: ciphertext, context: context }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/decrypt/#{name}", body).body)
          end

          def rewrap(name:, ciphertext:, mount: 'transit', **)
            vault_normalize(connection(**).post("/v1/#{mount}/rewrap/#{name}", { ciphertext: ciphertext }).body)
          end

          def datakey(name:, key_type: 'plaintext', mount: 'transit', **)
            vault_normalize(connection(**).post("/v1/#{mount}/datakey/#{key_type}/#{name}").body)
          end

          def sign(name:, input:, mount: 'transit', hash_algorithm: nil, **)
            body = { input: input, hash_algorithm: hash_algorithm }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/sign/#{name}", body).body)
          end

          def verify(name:, input:, signature:, mount: 'transit', hash_algorithm: nil, **)
            body = { input: input, signature: signature, hash_algorithm: hash_algorithm }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/verify/#{name}", body).body)
          end

          def hash_data(input:, mount: 'transit', algorithm: 'sha2-256', **)
            vault_normalize(connection(**).post("/v1/#{mount}/hash/#{algorithm}", { input: input }).body)
          end

          def random_bytes(bytes: 32, mount: 'transit', format: 'base64', **)
            vault_normalize(connection(**).post("/v1/#{mount}/random/#{bytes}", { format: format }).body)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
