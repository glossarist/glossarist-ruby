# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::LocalizedString do
  describe ".fetch" do
    it "returns the value for the requested language" do
      hash = { "eng" => "Hello", "fra" => "Bonjour" }
      expect(described_class.fetch(hash, "eng")).to eq("Hello")
      expect(described_class.fetch(hash, "fra")).to eq("Bonjour")
    end

    it "accepts symbol keys" do
      hash = { eng: "Hello", fra: "Bonjour" }
      expect(described_class.fetch(hash, "eng")).to eq("Hello")
    end

    it "falls back to English when requested language is missing" do
      hash = { "eng" => "Hello" }
      expect(described_class.fetch(hash, "deu")).to eq("Hello")
    end

    it "returns nil when language not found and no fallback" do
      hash = { "eng" => "Hello" }
      expect(described_class.fetch(hash, "deu", nil)).to be_nil
    end

    it "returns nil for nil hash" do
      expect(described_class.fetch(nil, "eng")).to be_nil
    end

    it "returns nil for empty hash" do
      expect(described_class.fetch({}, "eng")).to be_nil
    end
  end

  describe ".empty?" do
    it "returns true for nil" do
      expect(described_class.empty?(nil)).to be true
    end

    it "returns true for empty hash" do
      expect(described_class.empty?({})).to be true
    end

    it "returns false for non-empty hash" do
      expect(described_class.empty?({ "eng" => "Hi" })).to be false
    end
  end

  describe ".present?" do
    it "returns true for non-empty hash" do
      expect(described_class.present?({ "eng" => "Hi" })).to be true
    end

    it "returns false for nil" do
      expect(described_class.present?(nil)).to be false
    end
  end
end
