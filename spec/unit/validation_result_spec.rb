# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ValidationResult do
  describe "#valid?" do
    it "returns true when no errors" do
      result = described_class.new
      expect(result).to be_valid
    end

    it "returns false when errors present" do
      result = described_class.new
      result.add_error("something broke")
      expect(result).not_to be_valid
    end

    it "returns true when only warnings present" do
      result = described_class.new
      result.add_warning("minor issue")
      expect(result).to be_valid
    end
  end

  describe "#merge" do
    it "combines errors from both results" do
      a = described_class.new(errors: ["error 1"])
      b = described_class.new(errors: ["error 2"])

      a.merge(b)
      expect(a.errors).to eq(["error 1", "error 2"])
    end

    it "combines warnings from both results" do
      a = described_class.new(warnings: ["warn 1"])
      b = described_class.new(warnings: ["warn 2"])

      a.merge(b)
      expect(a.warnings).to eq(["warn 1", "warn 2"])
    end

    it "combines errors and warnings independently" do
      a = described_class.new(errors: ["e1"], warnings: ["w1"])
      b = described_class.new(errors: ["e2"], warnings: ["w2"])

      a.merge(b)
      expect(a.errors).to eq(["e1", "e2"])
      expect(a.warnings).to eq(["w1", "w2"])
    end

    it "returns self for chaining" do
      a = described_class.new
      b = described_class.new
      expect(a.merge(b)).to equal(a)
    end
  end

  describe "#to_h" do
    it "produces hash with valid, errors, warnings" do
      result = described_class.new
      result.add_warning("test")

      h = result.to_h
      expect(h["valid"]).to be true
      expect(h["errors"]).to eq([])
      expect(h["warnings"]).to eq(["test"])
    end
  end
end
