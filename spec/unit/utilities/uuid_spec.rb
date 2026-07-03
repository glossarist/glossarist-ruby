# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Utilities::UUID do
  describe ".uuid_v5" do
    it "produces identical output for identical inputs across calls (deterministic)" do
      uuid1 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "name1",
      )
      uuid2 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "name1",
      )
      expect(uuid1).to eq(uuid2)
    end

    it "produces different output for different names in the same namespace" do
      uuid1 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "name1",
      )
      uuid2 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "name2",
      )
      expect(uuid1).not_to eq(uuid2)
    end

    it "produces different output for same name in different namespaces" do
      uuid1 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "name",
      )
      uuid2 = described_class.uuid_v5(
        Glossarist::Utilities::UUID::DNS_NAMESPACE, "name",
      )
      expect(uuid1).not_to eq(uuid2)
    end

    it "sets the v5 version and RFC 4122 variant bits" do
      uuid = described_class.uuid_v5(
        Glossarist::Utilities::UUID::URL_NAMESPACE, "anything",
      )
      # Version 5 sits in the high nibble of the third group.
      expect(uuid[14]).to eq("5")
      # Variant 10xx sits in the high bits of the fourth group.
      expect(%w[8 9 a b]).to include(uuid[19])
    end

    it "accepts a string UUID namespace" do
      # The common case — caller passes a UUID string, not the precomputed
      # binary constant. This must not crash on ActiveSupport#present?
      # (the bug we are regression-testing here).
      uuid = described_class.uuid_v5(
        "6ba7b811-9dad-11d1-80b4-00c04fd430c8", "name",
      )
      expect(uuid).to match(/\A\h{8}-\h{4}-5\h{3}-[89ab]\h{3}-\h{12}\z/)
    end

    it "raises ArgumentError when the namespace is not a UUID" do
      # Regression: this used to crash with NoMethodError on MatchData#present?
      # because ActiveSupport wasn't loaded. It should raise ArgumentError
      # cleanly, regardless of ActiveSupport availability.
      expect {
        described_class.uuid_v5("not-a-uuid", "name")
      }.to raise_error(ArgumentError, /Only UUIDs are valid namespace identifiers/)
    end
  end
end

