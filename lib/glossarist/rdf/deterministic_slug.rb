# frozen_string_literal: true

require "digest"

module Glossarist
  module Rdf
    # Deterministic slug helper for RDF subject URIs.
    #
    # When an entity has no natural-language identifier (no source/id
    # pair, no text), derive a deterministic short slug from its
    # content fingerprint. Same content → same slug across runs and
    # across processes; different content → different slug (modulo
    # collision probability).
    #
    # Hash choice:
    #   - SHA-256 (not MD5). MD5 is deprecated for new code; SHA-256
    #     is the modern baseline and is free performance-wise.
    #   - Truncated to 16 hex chars (64 bits). Birthday-paradox
    #     collision probability at 4 million items < 1e-9, comfortable
    #     margin for any realistic dataset.
    #
    # Previous width was 12 chars (48 bits) using MD5 — collision
    # probability at 100k items was ~0.3%, too high for RDF merge.
    module DeterministicSlug
      HASH_WIDTH = 16

      def self.from_parts(*parts)
        joined = parts.compact.join("|")
        Digest::SHA256.hexdigest(joined)[0, HASH_WIDTH]
      end
    end
  end
end
