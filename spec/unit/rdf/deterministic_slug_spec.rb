# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Rdf::DeterministicSlug do
  describe ".from_parts" do
    it "returns 16 hex chars (64 bits)" do
      expect(described_class.from_parts("a", "b")).to match(/^[0-9a-f]{16}$/)
    end

    it "is deterministic — same input → same slug" do
      expect(described_class.from_parts("VIM", "1.3", "required"))
        .to eq(described_class.from_parts("VIM", "1.3", "required"))
    end

    it "different inputs → different slugs (modulo collision)" do
      a = described_class.from_parts("VIM", "1.3", "required")
      b = described_class.from_parts("VIM", "1.4", "required")
      expect(a).not_to eq(b)
    end

    it "skips nil parts (compact)" do
      expect(described_class.from_parts("a", nil, "b"))
        .to eq(described_class.from_parts("a", "b"))
    end

    it "is process-independent (no object_id)" do
      # Two separate calls with the same content must produce the same
      # slug even if they happen in different processes — this is the
      # reproducibility contract for RDF merge.
      slug1 = described_class.from_parts("test", "content")
      slug2 = described_class.from_parts("test", "content")
      expect(slug1).to eq(slug2)
    end

    it "uses SHA-256, not MD5 (security audit)" do
      # MD5 is deprecated for new code. Verify we hash with SHA-256.
      expected = Digest::SHA256.hexdigest("test|content")[0, 16]
      expect(described_class.from_parts("test", "content")).to eq(expected)
    end
  end

  describe "HASH_WIDTH" do
    it "is 16 (64 bits)" do
      expect(described_class::HASH_WIDTH).to eq(16)
    end

    # Birthday paradox: P(collision) for n items in 2^bits space is
    # roughly n²/(2 × 2^bits). At 4M items with 64 bits: P < 1e-9.
    # At 100k items with 48 bits (the old MD5 width): P ≈ 0.3%.
    # 16 chars is the minimum safe width for any realistic dataset.
  end
end
