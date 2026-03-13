# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Transit
          include Legion::Extensions::Vault::Helpers::Client

          def create_key(name:, mount: 'transit', type: nil, **)
            body = type ? { type: type } : {}
            response = connection(**).post("/v1/#{mount}/keys/#{name}", body)
            { result: response.status == 204 }
          end

          def read_key(name:, mount: 'transit', **)
            response = connection(**).get("/v1/#{mount}/keys/#{name}")
            { result: response.body }
          end

          def list_keys(mount: 'transit', **)
            response = connection(**).get("/v1/#{mount}/keys", { list: true })
            { result: response.body }
          end

          def delete_key(name:, mount: 'transit', **)
            response = connection(**).delete("/v1/#{mount}/keys/#{name}")
            { result: response.status == 204 }
          end

          def rotate_key(name:, mount: 'transit', **)
            response = connection(**).post("/v1/#{mount}/keys/#{name}/rotate")
            { result: response.status == 204 }
          end

          def encrypt(name:, plaintext:, mount: 'transit', context: nil, **)
            body = { plaintext: plaintext, context: context }.compact
            response = connection(**).post("/v1/#{mount}/encrypt/#{name}", body)
            { result: response.body }
          end

          def decrypt(name:, ciphertext:, mount: 'transit', context: nil, **)
            body = { ciphertext: ciphertext, context: context }.compact
            response = connection(**).post("/v1/#{mount}/decrypt/#{name}", body)
            { result: response.body }
          end

          def rewrap(name:, ciphertext:, mount: 'transit', **)
            response = connection(**).post("/v1/#{mount}/rewrap/#{name}", { ciphertext: ciphertext })
            { result: response.body }
          end

          def datakey(name:, key_type: 'plaintext', mount: 'transit', **)
            response = connection(**).post("/v1/#{mount}/datakey/#{key_type}/#{name}")
            { result: response.body }
          end

          def sign(name:, input:, mount: 'transit', hash_algorithm: nil, **)
            body = { input: input, hash_algorithm: hash_algorithm }.compact
            path = "/v1/#{mount}/sign/#{name}"
            response = connection(**).post(path, body)
            { result: response.body }
          end

          def verify(name:, input:, signature:, mount: 'transit', hash_algorithm: nil, **)
            body = { input: input, signature: signature, hash_algorithm: hash_algorithm }.compact
            path = "/v1/#{mount}/verify/#{name}"
            response = connection(**).post(path, body)
            { result: response.body }
          end

          def hash_data(input:, mount: 'transit', algorithm: 'sha2-256', **)
            response = connection(**).post("/v1/#{mount}/hash/#{algorithm}", { input: input })
            { result: response.body }
          end

          def random_bytes(bytes: 32, mount: 'transit', format: 'base64', **)
            response = connection(**).post("/v1/#{mount}/random/#{bytes}", { format: format })
            { result: response.body }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end
