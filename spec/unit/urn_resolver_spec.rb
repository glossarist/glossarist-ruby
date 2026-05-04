# frozen_string_literal: true

require "spec_helper"
require "cgi"

RSpec.describe Glossarist::UrnResolver do
  let(:resolver) { described_class.new }

  describe "IEC 60050 → Electropedia" do
    it "resolves simple IEV code" do
      url = resolver.resolve("urn:iec:std:iec:60050-102-01-01")
      expect(url).to eq(
        "https://www.electropedia.org/iev/iev.nsf/display?openform&ievref=#{CGI.escape('102-01-01')}",
      )
    end

    it "resolves dated IEV URN (ignores date)" do
      url = resolver.resolve("urn:iec:std:iec:60050-121-10-34:2016-11")
      expect(url).to include("ievref=121-10-34")
    end

    it "resolves fragment IEV URN" do
      url = resolver.resolve("urn:iec:std:iec:60050-121:2010-10::#con-121-10-23")
      expect(url).to include("ievref=121-10-23")
    end
  end

  describe "ISO → OBP" do
    it "resolves full ISO URN with term" do
      url = resolver.resolve("urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32")
      expect(url).to eq("https://www.iso.org/obp/ui/#iso:std:iso:19111:ed-3:v1:en:term:3.1.32")
    end

    it "resolves undated ISO URN" do
      url = resolver.resolve("urn:iso:std:iso:19111:term:3.1.32")
      expect(url).to eq("https://www.iso.org/obp/ui/#iso:std:iso:19111:term:3.1.32")
    end

    it "resolves whole-document ISO URN" do
      url = resolver.resolve("urn:iso:std:iso:19111:ed-3:v1:en")
      expect(url).to eq("https://www.iso.org/obp/ui/#iso:std:iso:19111:ed-3:v1:en")
    end
  end

  describe "from ConceptReference" do
    it "resolves IEC ConceptReference to Electropedia" do
      ref = Glossarist::ConceptReference.new(
        term: "equality",
        concept_id: "102-01-01",
        source: "urn:iec:std:iec:60050",
        ref_type: "urn",
      )
      url = resolver.resolve(ref)
      expect(url).to include("electropedia.org")
      expect(url).to include("102-01-01")
    end

    it "resolves ISO ConceptReference to OBP" do
      ref = Glossarist::ConceptReference.new(
        term: "geodetic latitude",
        concept_id: "3.1.32",
        source: "urn:iso:std:iso:19111",
        ref_type: "urn",
      )
      url = resolver.resolve(ref)
      expect(url).to eq("https://www.iso.org/obp/ui/#iso:std:iso:19111:term:3.1.32")
    end

    it "returns nil for local ConceptReference" do
      ref = Glossarist::ConceptReference.new(
        term: "latitude",
        concept_id: "200",
        ref_type: "local",
      )
      expect(resolver.resolve(ref)).to be_nil
    end

    it "returns nil for designation ConceptReference" do
      ref = Glossarist::ConceptReference.new(
        term: "geodetic latitude",
        ref_type: "designation",
      )
      expect(resolver.resolve(ref)).to be_nil
    end
  end

  describe "unknown URNs" do
    it "returns nil for unrecognized scheme" do
      expect(resolver.resolve("urn:example:foo:bar")).to be_nil
    end

    it "returns nil for non-URN strings" do
      expect(resolver.resolve("not-a-urn")).to be_nil
    end

    it "returns nil for nil input" do
      expect(resolver.resolve(nil)).to be_nil
    end
  end

  describe "custom scheme registration" do
    it "resolves custom URN scheme" do
      resolver.register_scheme("urn:example:") do |urn|
        "https://example.org/#{urn.sub('urn:example:', '')}"
      end

      url = resolver.resolve("urn:example:test:123")
      expect(url).to eq("https://example.org/test:123")
    end

    it "custom scheme does not interfere with built-in schemes" do
      resolver.register_scheme("urn:example:") do |urn|
        "https://example.org/#{urn}"
      end

      url = resolver.resolve("urn:iec:std:iec:60050-102-01-01")
      expect(url).to include("electropedia.org")
    end
  end

  describe ".resolve (class method)" do
    it "resolves without explicit instantiation" do
      url = described_class.resolve("urn:iec:std:iec:60050-102-01-01")
      expect(url).to include("electropedia.org")
    end
  end
end
